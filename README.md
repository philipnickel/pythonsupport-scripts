# Autoinstalling python 
## MacOS
Open a terminal (command + space, search for terminal) and run the following command:

```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallMacOS.sh)"
```
## Windows 

Paste following line in powershell in administrator mode. Search for powershell -> right click -> Run as administrator 


```{powershell}

PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/AutoInstallWindows.ps1' -UseBasicParsing).Content}"
```

