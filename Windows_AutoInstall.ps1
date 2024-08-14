# check for environmental variable DEVELOPERMODEPIS 
# if 1 set path_temp to 'philipnickel' otherwise set path_temp to 'dtudk'


$developerPath =  "https://raw.githubusercontent.com/$PS_remote/pythonsupport-scripts/$PS_branch/Autoinstall-scripts/Windows"


$productionPath =  "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Autoinstall-scripts/Windows"


if ($env:DEVELOPERMODEPS -eq 1) { $path_temp = $developerPath } else { $path_temp = $productionPath}


# link to full python installation 
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri '$path_temp/Windows_python.ps1' -UseBasicParsing).Content}"

# link to full VSC installation
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri '$path_temp/Windows_VSC.ps1' -UseBasicParsing).Content}"


