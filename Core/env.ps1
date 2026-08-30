# Shared environment configuration for DTU Python Support on Windows.

if (Test-Path Env:PS_OFFLINE) {
    throw "PS_OFFLINE is no longer supported; use PS_ENV=offline."
}

if ($env:PS_ENV_INITIALIZED -ne "1") {
    $defaultRepoUser = "dtudk"
    $defaultBranch = "main"
    $defaultRepoUrl = "https://raw.githubusercontent.com/$defaultRepoUser/pythonsupport-scripts/$defaultBranch"
    $defaultForgeUrl = "https://github.com/dtudk/pythonsupport-forge/releases/latest/download"

    $repoUrlSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_REPO_URL)
    $repoUserSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_REPO_USER)
    $branchSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_BRANCH)
    $forgeUrlSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_FORGE_URL)
    $vscodeUrlSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_VSCODE_URL)
    $bundleRootSupplied = -not [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT)

    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITEW6432) {
        $architecture = $env:PROCESSOR_ARCHITEW6432
    }
    switch ($architecture.ToUpperInvariant()) {
        "ARM64" {
            $env:PS_ARCH = "arm64"
            $env:PS_BUNDLE_PLATFORM = "windows-arm64"
            $env:PS_EXTENSION_PLATFORM = "win32-arm64"
            $defaultVsCodeUrl = "https://update.code.visualstudio.com/latest/win32-arm64-user/stable"
        }
        "AMD64" {
            $env:PS_ARCH = "x86_64"
            $env:PS_BUNDLE_PLATFORM = "windows-x64"
            $env:PS_EXTENSION_PLATFORM = "win32-x64"
            $defaultVsCodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        }
        default { throw "Unsupported Windows architecture: $architecture" }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:PS_ENV)) {
        if ($env:PS_ENV -notin @("main", "offline", "custom")) {
            throw "Invalid PS_ENV '$($env:PS_ENV)'; expected main, offline, or custom."
        }
    } elseif ($bundleRootSupplied) {
        $env:PS_ENV = "offline"
    } elseif ($repoUrlSupplied -or $repoUserSupplied -or $branchSupplied -or $forgeUrlSupplied -or $vscodeUrlSupplied) {
        $env:PS_ENV = "custom"
    } else {
        $env:PS_ENV = "main"
    }

    switch ($env:PS_ENV) {
        "main" {
            if ($bundleRootSupplied -or $repoUrlSupplied -or $repoUserSupplied -or $branchSupplied -or $forgeUrlSupplied -or $vscodeUrlSupplied) {
                throw "PS_ENV=main cannot be combined with repository, asset, or bundle overrides."
            }
            $env:PS_REPO_USER = $defaultRepoUser
            $env:PS_BRANCH = $defaultBranch
            $env:PS_REPO_URL = $defaultRepoUrl
            $env:PS_FORGE_URL = $defaultForgeUrl
            $env:PS_VSCODE_URL = $defaultVsCodeUrl
            $env:PS_BUNDLE_ROOT = ""
        }
        "custom" {
            if ($bundleRootSupplied) {
                throw "PS_ENV=custom cannot be combined with PS_BUNDLE_ROOT."
            }
            if (-not ($repoUrlSupplied -or $repoUserSupplied -or $branchSupplied -or $forgeUrlSupplied -or $vscodeUrlSupplied)) {
                throw "PS_ENV=custom requires a repository or asset-source override."
            }
            if ($repoUrlSupplied -and ($repoUserSupplied -or $branchSupplied)) {
                throw "PS_REPO_URL cannot be combined with PS_REPO_USER or PS_BRANCH."
            }
            if (-not $repoUrlSupplied) {
                if (-not $repoUserSupplied) { $env:PS_REPO_USER = $defaultRepoUser }
                if (-not $branchSupplied) { $env:PS_BRANCH = $defaultBranch }
                $env:PS_REPO_URL = "https://raw.githubusercontent.com/$($env:PS_REPO_USER)/pythonsupport-scripts/$($env:PS_BRANCH)"
            } else {
                $env:PS_REPO_URL = ($env:PS_REPO_URL).TrimEnd('/')
            }
            if (-not $forgeUrlSupplied) { $env:PS_FORGE_URL = $defaultForgeUrl }
            if (-not $vscodeUrlSupplied) { $env:PS_VSCODE_URL = $defaultVsCodeUrl }
            $env:PS_BUNDLE_ROOT = ""
        }
        "offline" {
            if ($repoUrlSupplied -or $repoUserSupplied -or $branchSupplied -or $forgeUrlSupplied -or $vscodeUrlSupplied) {
                throw "PS_ENV=offline cannot be combined with online repository or asset overrides."
            }
            if (-not $bundleRootSupplied) {
                throw "PS_BUNDLE_ROOT is required when PS_ENV=offline."
            }
            $env:PS_REPO_URL = $env:PS_BUNDLE_ROOT
            $env:PS_FORGE_URL = ""
            $env:PS_VSCODE_URL = ""
        }
    }

    $env:PS_ENV_INITIALIZED = "1"
}

function global:Invoke-RepositoryScript {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or
        [System.IO.Path]::IsPathRooted($RelativePath) -or
        (($RelativePath -split '[\\/]') -contains '..')) {
        throw "Repository script path must be a safe relative path: $RelativePath"
    }

    if ($env:PS_ENV -eq "offline") {
        $scriptPath = Join-Path $env:PS_BUNDLE_ROOT ($RelativePath -replace '/', '\')
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            throw "Missing offline script: $scriptPath"
        }
        & $scriptPath
        return
    }

    $content = (Invoke-WebRequest -Uri "$($env:PS_REPO_URL)/$RelativePath" -UseBasicParsing).Content
    & ([ScriptBlock]::Create($content))
}
