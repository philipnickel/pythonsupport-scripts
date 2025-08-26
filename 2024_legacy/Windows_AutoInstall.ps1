# Define the prefix variable
$_prefix = "PYS:"

# checks for environmental variables for remote and branch
if (-not $env:REMOTE_PS) {
    $env:REMOTE_PS = "dtudk/pythonsupport-scripts"
}
if (-not $env:BRANCH_PS) {
    $env:BRANCH_PS = "main"
}

$url_ps = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows"

Write-Output "$_prefix URL used for fetching scripts $url_ps"

PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri '$url_ps/Python/Install.ps1' -UseBasicParsing).Content}"
$_python_ret = $?

PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri '$url_ps/VSC/Install.ps1' -UseBasicParsing).Content}"
$_vsc_ret = $?


function Exit-Message {
    Write-Output ""
    Write-Output "Something went wrong in one of the installation runs."
    Write-Output "Please see further up in the output for an error message..."
    Write-Output ""
}

if ( -not $_python_ret ) {
  Exit-Message
  exit $_python_ret
} elseif ( -not $_vsc_ret ) {
  Exit-Message
  exit $_vsc_ret
}

Write-Output ""
Write-Output ""
Write-Output "Script has finished. You may now close the terminal..."
