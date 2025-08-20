# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## Quick Diagnostics

Run comprehensive Python environment diagnostics:

```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash
```

# Autoinstalling python 
## MacOS
Open a terminal (command + space, search for terminal) and run the following command:

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS_AutoInstall.sh)"
```
## Windows 

Paste following line in powershell in administrator mode. Search for powershell -> right click -> Run as administrator 


```{powershell}

PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows_AutoInstall.ps1' -UseBasicParsing).Content}"
```

# Pilot: Installing dependencies for converting notebooks to pdf in VS Code 

**_NOTE:_** Works as of September 2. 2024. However, some notebooks may not be possible to convert...


## MacOS

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Latex/Install.sh)"
```



## Windows 


```{powershell}

PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Latex/Install.ps1' -UseBasicParsing).Content}"
```


# Running Health Check script
## Windows 
**_NOTE:_** The Health Check script only checks in the currently active Conda environment

Paste following line in powershell after activating the desired enviroment

```{powershell}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/HealthCheck/Windows/Health_Check.ps1' -UseBasicParsing).Content
```

## MacOS

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/refs/heads/main/HealthCheck/MacOS/Health_Check.sh) -v"
```
