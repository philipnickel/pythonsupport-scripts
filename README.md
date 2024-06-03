# Autoinstalling python 
## MacOS
Open a terminal and run the following command:

```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallMacOS.sh)"
```


# Checking for multiple versions of VsCode
Run the following command in a terminal 

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/multipleVersionsMac.sh)"
```

# Installing dependancies for converting Jupyter notebooks to PDFs.
## MacOS
Open a terminal and run the following command:

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/script_VsCode_PDF-fix_MacOS.sh)"
```
## Windows

Open powershell in administrator mode. Search for powershell -> right click -> Run as administrator 

Run the following command: 

```{powershell}
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/windows_pdf_fix.ps1' -UseBasicParsing).Content}"
```
# Deleting Homebrew 
```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```
# One liner install Homebrew

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  && (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.zshrc && (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> ~/.bash_profile && eval "$(/usr/local/bin/brew shellenv)" && echo "Homebrew installed. Note: You do not need to run anything else in the terminal" && exit
```
