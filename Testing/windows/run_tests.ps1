#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$script:repoUrl = $env:PS_REPO_URL
if (-not $script:repoUrl) {
    $script:repoUrl = "http://127.0.0.1:8000"
}
$script:repoUrl = $script:repoUrl.TrimEnd("/")

$script:originalEnvironment = @{
    USERPROFILE = $env:USERPROFILE
    APPDATA = $env:APPDATA
    LOCALAPPDATA = $env:LOCALAPPDATA
    TEMP = $env:TEMP
    TMP = $env:TMP
    TMPDIR = $env:TMPDIR
    PATH = $env:PATH
    PS_REPO_URL = $env:PS_REPO_URL
    PS_FORGE_URL = $env:PS_FORGE_URL
    PS_VSCODE_URL = $env:PS_VSCODE_URL
    PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
    PROGRESS_LOG_FILE = $env:PROGRESS_LOG_FILE
    PS_TEST_CODE_LOG = $env:PS_TEST_CODE_LOG
    PS_TEST_CODE_FAIL = $env:PS_TEST_CODE_FAIL
    PS_TEST_CONDA_EXIT_CODE = $env:PS_TEST_CONDA_EXIT_CODE
    PS_TEST_VSCODE_EXIT_CODE = $env:PS_TEST_VSCODE_EXIT_CODE
}

$script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dtu windows tests " + [System.Guid]::NewGuid())
$script:failures = @()
$script:passed = 0
$script:currentCaseRoot = $null
$global:DTUTestProcessCalls = @()
$global:DTUTestWebRequests = @()

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-False {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    Assert-True -Condition (-not $Condition) -Message $Message
}

function Assert-Equal {
    param(
        [AllowNull()]$Expected,
        [AllowNull()]$Actual,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Expected -ne $Actual) {
        throw "$Message`nExpected: <$Expected>`nActual:   <$Actual>"
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Text.Contains($Expected)) {
        throw "$Message`nMissing: <$Expected>`nOutput:`n$Text"
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Unexpected,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Text.Contains($Unexpected)) {
        throw "$Message`nUnexpected: <$Unexpected>`nOutput:`n$Text"
    }
}

function Invoke-Test {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Test
    )

    try {
        & $Test
        $script:passed++
        Write-Host "[PASS] $Name" -ForegroundColor Green
    } catch {
        $script:failures += "$Name`: $($_.Exception.Message)"
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        Write-Host "       $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-RepoContent {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    return (Microsoft.PowerShell.Utility\Invoke-WebRequest `
        -Uri "$script:repoUrl/$RelativePath" -UseBasicParsing).Content
}

function Invoke-ContentCaptured {
    param([Parameter(Mandatory = $true)][string]$Content)

    $script:capturedError = $null
    $output = & {
        try {
            Invoke-Expression $Content
        } catch {
            $script:capturedError = $_
        }
    } *>&1 | Out-String

    return [pscustomobject]@{
        Output = $output
        Error = $script:capturedError
    }
}

function Invoke-RepoScript {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    return Invoke-ContentCaptured -Content (Get-RepoContent -RelativePath $RelativePath)
}

function New-FakeCodeCli {
    $codeCli = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    $codeDir = Split-Path -Parent $codeCli
    New-Item -ItemType Directory -Path $codeDir -Force | Out-Null

    $scriptText = @'
#!/bin/sh
printf '%s\n' "$*" >> "$PS_TEST_CODE_LOG"
if [ -n "$PS_TEST_CODE_FAIL" ]; then
    if printf '%s\n' "$*" | grep -F -q -- "$PS_TEST_CODE_FAIL"; then
        exit 23
    fi
fi
exit 0
'@
    [System.IO.File]::WriteAllText($codeCli, $scriptText.Replace("`r`n", "`n"))
    & chmod +x $codeCli
    if ($LASTEXITCODE -ne 0) {
        throw "Could not make the fake VS Code CLI executable."
    }
    return $codeCli
}

function Reset-TestEnvironment {
    param([Parameter(Mandatory = $true)][string]$Name)

    $safeName = $Name -replace '[^A-Za-z0-9_.-]', '_'
    $script:currentCaseRoot = Join-Path $script:testRoot $safeName
    if (Test-Path $script:currentCaseRoot) {
        Remove-Item -Recurse -Force $script:currentCaseRoot
    }

    $userProfile = Join-Path $script:currentCaseRoot "User Profile"
    $appData = Join-Path $userProfile "App Data/Roaming"
    $localAppData = Join-Path $userProfile "App Data/Local"
    $tempDir = Join-Path $script:currentCaseRoot "Temporary Files"
    New-Item -ItemType Directory -Path $appData, $localAppData, $tempDir -Force | Out-Null

    $env:USERPROFILE = $userProfile
    $env:APPDATA = $appData
    $env:LOCALAPPDATA = $localAppData
    $env:TEMP = $tempDir
    $env:TMP = $tempDir
    $env:TMPDIR = $tempDir
    $env:PATH = $script:originalEnvironment.PATH
    $env:PS_REPO_URL = $script:repoUrl
    $env:PS_FORGE_URL = "$script:repoUrl/Testing/windows/fixtures"
    $env:PS_VSCODE_URL = "$script:repoUrl/Testing/windows/fixtures/VSCode.exe"
    $env:PROCESSOR_ARCHITECTURE = "AMD64"
    $env:PROGRESS_LOG_FILE = Join-Path $tempDir "dtu_log.txt"
    $env:PS_TEST_CODE_LOG = Join-Path $tempDir "code calls.log"
    $env:PS_TEST_CODE_FAIL = $null
    $env:PS_TEST_CONDA_EXIT_CODE = "0"
    $env:PS_TEST_VSCODE_EXIT_CODE = "0"

    $global:DTUTestProcessCalls = @()
    $global:DTUTestWebRequests = @()
}

function global:Start-Process {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [object[]]$ArgumentList,
        [switch]$NoNewWindow,
        [switch]$Wait,
        [switch]$PassThru,
        [string]$RedirectStandardOutput
    )

    $leafName = [System.IO.Path]::GetFileName($FilePath)
    $arguments = if ($ArgumentList) { $ArgumentList -join " " } else { "" }
    $global:DTUTestProcessCalls += [pscustomobject]@{
        FilePath = $FilePath
        LeafName = $leafName
        Arguments = $arguments
        NoNewWindow = [bool]$NoNewWindow
        Wait = [bool]$Wait
        PassThru = [bool]$PassThru
        RedirectStandardOutput = $RedirectStandardOutput
    }

    if ($leafName -like "Miniforge3-Windows-*.exe") {
        $exitCode = [int]$env:PS_TEST_CONDA_EXIT_CODE
        if ($RedirectStandardOutput) {
            [System.IO.File]::WriteAllText($RedirectStandardOutput, "fake Miniforge installer output")
        }
        if ($exitCode -eq 0) {
            $condaExe = Join-Path $env:USERPROFILE "miniforge3-dtu/Scripts/conda.exe"
            New-Item -ItemType Directory -Path (Split-Path -Parent $condaExe) -Force | Out-Null
            [System.IO.File]::WriteAllText($condaExe, "test marker")
        }
    } elseif ($leafName -eq "VSCode.exe") {
        $exitCode = [int]$env:PS_TEST_VSCODE_EXIT_CODE
        if ($exitCode -eq 0) {
            New-FakeCodeCli | Out-Null
        }
    } else {
        throw "Unexpected Start-Process target in test: $FilePath"
    }

    return [pscustomobject]@{ ExitCode = $exitCode }
}

function Invoke-VSCodeWithDownloadCapture {
    param([Parameter(Mandatory = $true)][string]$Content)

    $script:capturedError = $null
    $output = & {
        function Invoke-WebRequest {
            param(
                [Parameter(Mandatory = $true)][string]$Uri,
                [string]$OutFile,
                [switch]$UseBasicParsing
            )
            $global:DTUTestWebRequests += $Uri
            if (-not $OutFile) {
                throw "The architecture test expected a download destination."
            }
            [System.IO.File]::WriteAllText($OutFile, "fake installer")
            return [pscustomobject]@{ Content = "" }
        }

        try {
            Invoke-Expression $Content
        } catch {
            $script:capturedError = $_
        }
    } *>&1 | Out-String

    return [pscustomobject]@{
        Output = $output
        Error = $script:capturedError
    }
}

try {
    New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null

    Invoke-Test "PowerShell syntax parses" {
        $parseFailures = @()
        Get-ChildItem -Path $script:repoRoot -Filter "*.ps1" -File -Recurse | ForEach-Object {
            $tokens = $null
            $parseErrors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile(
                $_.FullName, [ref]$tokens, [ref]$parseErrors
            )
            if ($parseErrors.Count -gt 0) {
                $parseFailures += "$($_.FullName): $($parseErrors -join '; ')"
            }
        }
        Assert-Equal -Expected 0 -Actual $parseFailures.Count `
            -Message ("PowerShell parse failure(s):`n" + ($parseFailures -join "`n"))
    }

    Invoke-Test "Settings are created exactly once" {
        Reset-TestEnvironment "settings create"
        $result = Invoke-RepoScript "Core/VsCode/config/settings_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Settings script failed: $($result.Error)"

        $settingsFile = Join-Path $env:APPDATA "Code/User/settings.json"
        Assert-True -Condition (Test-Path $settingsFile) -Message "settings.json was not created."
        $expected = [System.IO.File]::ReadAllText((Join-Path $script:repoRoot "Core/VsCode/config/default_settings_Windows.json"))
        $actual = [System.IO.File]::ReadAllText($settingsFile)
        Assert-Equal -Expected $expected -Actual $actual -Message "Installed settings differ from the tracked defaults."
    }

    Invoke-Test "Existing settings are preserved" {
        Reset-TestEnvironment "settings preserve"
        $settingsFile = Join-Path $env:APPDATA "Code/User/settings.json"
        New-Item -ItemType Directory -Path (Split-Path -Parent $settingsFile) -Force | Out-Null
        $sentinel = '{"existing":true}'
        [System.IO.File]::WriteAllText($settingsFile, $sentinel)

        $result = Invoke-RepoScript "Core/VsCode/config/settings_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Existing settings caused a failure."
        Assert-Contains -Text $result.Output -Expected "[WARNING]" -Message "Preservation warning was not printed."
        Assert-Equal -Expected $sentinel -Actual ([System.IO.File]::ReadAllText($settingsFile)) `
            -Message "Existing settings were changed."
    }

    Invoke-Test "Extensions ignore comments and install every ID" {
        Reset-TestEnvironment "extensions success"
        New-FakeCodeCli | Out-Null
        $result = Invoke-RepoScript "Core/VsCode/config/extensions_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Extensions script failed: $($result.Error)"

        $calls = @(Get-Content $env:PS_TEST_CODE_LOG)
        Assert-Equal -Expected 2 -Actual $calls.Count -Message "Unexpected number of extension CLI calls."
        Assert-Equal -Expected "--install-extension ms-python.python --force" -Actual $calls[0] `
            -Message "Python extension arguments were incorrect."
        Assert-Equal -Expected "--install-extension ms-toolsai.jupyter --force" -Actual $calls[1] `
            -Message "Jupyter extension arguments were incorrect."
    }

    Invoke-Test "Extension failures try all IDs and then fail" {
        Reset-TestEnvironment "extensions failure"
        $codeCli = New-FakeCodeCli
        $env:PS_TEST_CODE_FAIL = "ms-python.python"
        & $codeCli --install-extension ms-python.python --force
        Assert-Equal -Expected 23 -Actual $LASTEXITCODE `
            -Message "The fake VS Code CLI did not produce its configured failure."
        Remove-Item $env:PS_TEST_CODE_LOG -Force
        $result = Invoke-RepoScript "Core/VsCode/config/extensions_windows.ps1"

        Assert-True -Condition ($null -ne $result.Error) `
            -Message "An extension failure was reported as success.`nOutput:`n$($result.Output)"
        Assert-Contains -Text $result.Output -Expected "[FAIL] ms-python.python" `
            -Message "The failed extension was not reported."
        $calls = @(Get-Content $env:PS_TEST_CODE_LOG)
        Assert-Equal -Expected 2 -Actual $calls.Count -Message "Processing stopped before every extension was attempted."
    }

    Invoke-Test "Conda fresh install uses the silent contract and cleans up" {
        Reset-TestEnvironment "conda fresh"
        $result = Invoke-RepoScript "Core/Conda/install/install_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Conda install failed: $($result.Error)"
        Assert-Equal -Expected 1 -Actual $global:DTUTestProcessCalls.Count `
            -Message "Conda should execute exactly one installer."

        $call = $global:DTUTestProcessCalls[0]
        Assert-Equal -Expected "Miniforge3-Windows-x86_64.exe" -Actual $call.LeafName `
            -Message "Unexpected Conda installer name."
        $expectedArgs = "/S /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /D=$(Join-Path $env:USERPROFILE 'miniforge3-dtu')"
        Assert-Equal -Expected $expectedArgs -Actual $call.Arguments -Message "Conda installer arguments changed."
        Assert-True -Condition $call.Wait -Message "Conda installer was not awaited."
        Assert-True -Condition $call.PassThru -Message "Conda installer process was not captured."
        Assert-False -Condition (Test-Path (Split-Path -Parent $call.FilePath)) `
            -Message "Conda temporary directory was not removed."
    }

    Invoke-Test "Conda already-installed and ARM64 branches behave correctly" {
        Reset-TestEnvironment "conda installed arm"
        $env:PROCESSOR_ARCHITECTURE = "ARM64"
        $condaExe = Join-Path $env:USERPROFILE "miniforge3-dtu/Scripts/conda.exe"
        New-Item -ItemType Directory -Path (Split-Path -Parent $condaExe) -Force | Out-Null
        [System.IO.File]::WriteAllText($condaExe, "existing")

        $result = Invoke-RepoScript "Core/Conda/install/install_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Installed Conda branch failed."
        Assert-Equal -Expected 0 -Actual $global:DTUTestProcessCalls.Count `
            -Message "Already-installed Conda unexpectedly ran an installer."
        Assert-Contains -Text $result.Output -Expected "using the x64 installer" `
            -Message "ARM64 emulation guidance was not printed."
        Assert-Contains -Text $result.Output -Expected "Skipping download" `
            -Message "Already-installed Conda was not reported."
    }

    Invoke-Test "Conda installer failures propagate and clean up" {
        Reset-TestEnvironment "conda failure"
        $env:PS_TEST_CONDA_EXIT_CODE = "41"
        $result = Invoke-RepoScript "Core/Conda/install/install_windows.ps1"

        Assert-True -Condition ($null -ne $result.Error) -Message "Conda installer failure was reported as success."
        Assert-Contains -Text "$($result.Error)" -Expected "exited with code 41" `
            -Message "Conda exit code was not propagated."
        $call = $global:DTUTestProcessCalls[0]
        Assert-False -Condition (Test-Path (Split-Path -Parent $call.FilePath)) `
            -Message "Failed Conda install left its temporary directory behind."
    }

    Invoke-Test "VS Code fresh install configures settings and extensions" {
        Reset-TestEnvironment "vscode fresh"
        $result = Invoke-RepoScript "Core/VsCode/install/install_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "VS Code install failed: $($result.Error)"
        Assert-Equal -Expected 1 -Actual $global:DTUTestProcessCalls.Count `
            -Message "VS Code should execute exactly one installer."

        $call = $global:DTUTestProcessCalls[0]
        Assert-Equal -Expected "VSCode.exe" -Actual $call.LeafName -Message "Unexpected VS Code installer name."
        Assert-Equal -Expected "/silent /mergetasks=!runcode" -Actual $call.Arguments `
            -Message "VS Code silent arguments changed."
        Assert-True -Condition $call.Wait -Message "VS Code installer was not awaited."
        Assert-True -Condition $call.PassThru -Message "VS Code installer process was not captured."
        Assert-False -Condition (Test-Path (Split-Path -Parent $call.FilePath)) `
            -Message "VS Code temporary directory was not removed."
        Assert-True -Condition (Test-Path (Join-Path $env:APPDATA "Code/User/settings.json")) `
            -Message "VS Code settings were not installed."
        Assert-Equal -Expected 2 -Actual @(Get-Content $env:PS_TEST_CODE_LOG).Count `
            -Message "VS Code extensions were not installed."
    }

    Invoke-Test "VS Code already-installed branch still applies configuration" {
        Reset-TestEnvironment "vscode installed"
        New-FakeCodeCli | Out-Null
        $result = Invoke-RepoScript "Core/VsCode/install/install_windows.ps1"

        Assert-True -Condition ($null -eq $result.Error) -Message "Installed VS Code branch failed."
        Assert-Equal -Expected 0 -Actual $global:DTUTestProcessCalls.Count `
            -Message "Already-installed VS Code unexpectedly ran an installer."
        Assert-Contains -Text $result.Output -Expected "Skipping download" `
            -Message "Already-installed VS Code was not reported."
        Assert-True -Condition (Test-Path (Join-Path $env:APPDATA "Code/User/settings.json")) `
            -Message "Settings were not applied to existing VS Code."
        Assert-Equal -Expected 2 -Actual @(Get-Content $env:PS_TEST_CODE_LOG).Count `
            -Message "Extensions were not applied to existing VS Code."
    }

    Invoke-Test "VS Code installer failures propagate and clean up" {
        Reset-TestEnvironment "vscode failure"
        $env:PS_TEST_VSCODE_EXIT_CODE = "37"
        $result = Invoke-RepoScript "Core/VsCode/install/install_windows.ps1"

        Assert-True -Condition ($null -ne $result.Error) -Message "VS Code installer failure was reported as success."
        Assert-Contains -Text "$($result.Error)" -Expected "exited with code 37" `
            -Message "VS Code exit code was not propagated."
        $call = $global:DTUTestProcessCalls[0]
        Assert-False -Condition (Test-Path (Split-Path -Parent $call.FilePath)) `
            -Message "Failed VS Code install left its temporary directory behind."
        Assert-False -Condition (Test-Path (Join-Path $env:APPDATA "Code/User/settings.json")) `
            -Message "Configuration ran after the VS Code installer failed."
    }

    Invoke-Test "VS Code selects x64 and ARM64 production downloads" {
        $content = Get-RepoContent "Core/VsCode/install/install_windows.ps1"

        Reset-TestEnvironment "vscode x64 url"
        $env:PS_VSCODE_URL = $null
        $env:PS_TEST_VSCODE_EXIT_CODE = "99"
        $x64 = Invoke-VSCodeWithDownloadCapture -Content $content
        Assert-True -Condition ($null -ne $x64.Error) -Message "x64 URL test should stop at the fake installer."
        Assert-Equal -Expected "https://update.code.visualstudio.com/latest/win32-x64-user/stable" `
            -Actual $global:DTUTestWebRequests[0] -Message "Incorrect x64 VS Code URL."

        Reset-TestEnvironment "vscode arm64 url"
        $env:PS_VSCODE_URL = $null
        $env:PROCESSOR_ARCHITECTURE = "ARM64"
        $env:PS_TEST_VSCODE_EXIT_CODE = "99"
        $arm64 = Invoke-VSCodeWithDownloadCapture -Content $content
        Assert-True -Condition ($null -ne $arm64.Error) -Message "ARM64 URL test should stop at the fake installer."
        Assert-Equal -Expected "https://update.code.visualstudio.com/latest/win32-arm64-user/stable" `
            -Actual $global:DTUTestWebRequests[0] -Message "Incorrect ARM64 VS Code URL."
    }

    Invoke-Test "Full orchestration succeeds in order with paths containing spaces" {
        Reset-TestEnvironment "orchestration success with spaces"
        $result = Invoke-RepoScript "Core/Orchestration/install_all_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Full orchestration failed: $($result.Error)"
        Assert-Equal -Expected 2 -Actual $global:DTUTestProcessCalls.Count `
            -Message "Full install did not execute both installers."
        Assert-Equal -Expected "Miniforge3-Windows-x86_64.exe" -Actual $global:DTUTestProcessCalls[0].LeafName `
            -Message "Conda was not installed first."
        Assert-Equal -Expected "VSCode.exe" -Actual $global:DTUTestProcessCalls[1].LeafName `
            -Message "VS Code was not installed second."
        Assert-Contains -Text $result.Output -Expected "Installation complete!" `
            -Message "Success banner was not printed."
        Assert-Contains -Text $result.Output -Expected "Open Miniforge Prompt" `
            -Message "Miniforge Prompt guidance was not printed."
        Assert-NotContains -Text $result.Output -Unexpected "demo failure" `
            -Message "Loading progress.ps1 ran its self-test."
        Assert-True -Condition $global:DTUTestProcessCalls[0].Arguments.Contains($env:USERPROFILE) `
            -Message "The Conda install path with spaces was not preserved in the installer arguments."
    }

    Invoke-Test "Full orchestration preserves existing settings on rerun" {
        Reset-TestEnvironment "orchestration rerun"
        $settingsFile = Join-Path $env:APPDATA "Code/User/settings.json"
        New-Item -ItemType Directory -Path (Split-Path -Parent $settingsFile) -Force | Out-Null
        $sentinel = '{"studentPreference":"keep"}'
        [System.IO.File]::WriteAllText($settingsFile, $sentinel)

        $result = Invoke-RepoScript "Core/Orchestration/install_all_windows.ps1"
        Assert-True -Condition ($null -eq $result.Error) -Message "Rerun orchestration failed: $($result.Error)"
        Assert-Equal -Expected $sentinel -Actual ([System.IO.File]::ReadAllText($settingsFile)) `
            -Message "Full orchestration overwrote existing settings."
        Assert-Equal -Expected 2 -Actual @(Get-Content $env:PS_TEST_CODE_LOG).Count `
            -Message "Extensions were skipped when existing settings were preserved."
        Assert-Contains -Text $result.Output -Expected "Installation complete!" `
            -Message "Rerun did not complete successfully."
    }

    Invoke-Test "Full orchestration suppresses success after installer failure" {
        Reset-TestEnvironment "orchestration installer failure"
        $env:PS_TEST_VSCODE_EXIT_CODE = "17"
        $result = Invoke-RepoScript "Core/Orchestration/install_all_windows.ps1"

        Assert-True -Condition ($null -ne $result.Error) -Message "Orchestration swallowed an installer failure."
        Assert-Equal -Expected 2 -Actual $global:DTUTestProcessCalls.Count `
            -Message "Unexpected installer sequence before failure."
        Assert-NotContains -Text $result.Output -Unexpected "Installation complete!" `
            -Message "A false success banner was printed."
    }

    Invoke-Test "Full orchestration suppresses success after extension failure" {
        Reset-TestEnvironment "orchestration extension failure"
        $env:PS_TEST_CODE_FAIL = "ms-python.python"
        $result = Invoke-RepoScript "Core/Orchestration/install_all_windows.ps1"

        Assert-True -Condition ($null -ne $result.Error) -Message "Orchestration swallowed an extension failure."
        Assert-Equal -Expected 2 -Actual @(Get-Content $env:PS_TEST_CODE_LOG).Count `
            -Message "Not every extension was attempted before orchestration failed."
        Assert-NotContains -Text $result.Output -Unexpected "Installation complete!" `
            -Message "A false success banner was printed after an extension failure."
    }
} finally {
    foreach ($name in $script:originalEnvironment.Keys) {
        [System.Environment]::SetEnvironmentVariable($name, $script:originalEnvironment[$name], "Process")
    }
    if (Test-Path $script:testRoot) {
        Remove-Item -Recurse -Force $script:testRoot -ErrorAction SilentlyContinue
    }
    Remove-Item Function:\global:Start-Process -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "$script:passed test(s) passed; $($script:failures.Count) failed."
if ($script:failures.Count -gt 0) {
    Write-Host ($script:failures -join "`n") -ForegroundColor Red
    throw "Windows PowerShell integration tests failed."
}
