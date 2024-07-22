# echo 
Write-Host "Script by Python Installation Support DTU"
Write-Host "This script will install python along with visual studio code - and everything you need to get started with programming"


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

# install miniconda using chocolatey

choco install miniconda3 -y

RefreshEnv

# isntall the GUI

conda install anaconda-navigator -yes

# ensure version of python 

conda install python=3.11 -yes 

# install packages 

conda install -c conda-forge dtumathtools uncertainties 

# install vs-code 

choco install vscode -y 
RefreshEnv 

# install extensions 

# install python extension, jupyter, vscode-pdf
#python extension
code --install-extension ms-python.python
#jupyter extension
code --install-extension ms-toolsai.jupyter
#pdf extension (for viewing pdfs inside vs code)
code --install-extension tomoki1207.pdf

Write-Host "Script finished"
