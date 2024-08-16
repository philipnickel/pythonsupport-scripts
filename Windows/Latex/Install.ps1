# echo 
Write-Host "Script by Python Installation Support DTU"
Write-Host "This script will install dependencies for exporting Jupyter Notebooks to PDF in Visual Studio Code."


Write-Host "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
Start-Sleep -Seconds 1

# check for chocolatey
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey is already installed."
}
else {
    Write-Host "Chocolatey is not installed. Installing chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# reset terminal to use chocolatey
RefreshEnv

# check for pandoc
if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    Write-Host "Pandoc is already installed."
}
else {
    Write-Host "Pandoc is not installed. Installing pandoc..."
    choco install pandoc -y
}

# check for miktex
if (Get-Command miktex -ErrorAction SilentlyContinue) {
    Write-Host "Miktex is already installed."
}
else {
    Write-Host "Miktex is not installed. Installing miktex..."
    choco install miktex -y
}

# reset terminal to use miktex
RefreshEnv


Write-Host "Updating nbconvert..."
pip install --force-reinstall nbconvert

Write-Host "Script finished."
Write-Host "Please make sure to restart visual studio code for the changes to take effect."
Write-Host "If you have multiple versions of python installed and pdf exporting doesn't work,  try running 'python3 -m pip install --force-reinstall nbconvert' for the version of python you are using in your notebook. You can do this directly in the vs code terminal (terminal -> new terminal)"
Write-Host "If it still doesn't work resolve to using pdf export via HTML (Export as HTML and then convert to pdf using a browser)."
