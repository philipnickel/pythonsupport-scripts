# Autoinstalling python 
## MacOS
Open a terminal and run the following command:

```{bash}

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/AutoInstallMacOS.sh)"
```


# Checking for multiple versions of VsCode
Run the following command in a terminal 

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/multipleVersionsMac.sh)"
```

# Installing dependancies for converting Jupyter notebooks to PDFs.
## MacOS
Open a terminal and run the following command:

```{bash}
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/script_VsCode_PDF-fix_MacOS.sh)"
```
## Windows

Open powershell in administrator mode. Search for powershell -> right click -> Run as administrator 

Run the following command: 

```{powershell}
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/windows_pdf_fix.ps1' -UseBasicParsing).Content}"
```



