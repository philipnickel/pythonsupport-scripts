# Installing dependancies for converting Jupyter notebooks to PDFs.
## MacOS
Open a terminal and run the following command:

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Latex/Install.sh)"
```
## Windows

Open powershell in administrator mode. Search for powershell -> right click -> Run as administrator 

Run the following command: 

```{powershell}
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Latex/Install.ps1' -UseBasicParsing).Content}"
```

# Deleting Homebrew 
```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```


# One liner install Homebrew

```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Homebrew/Install.sh)"
```

# Deleting Python 


```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Python/deletePythonMac.sh)"
```

