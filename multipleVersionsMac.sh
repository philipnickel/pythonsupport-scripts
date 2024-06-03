# This script is used to check for multiple versions of VsCode on Mac
# It will list all the versions of VsCode installed on the machine

# Searches in Downloads, Applications and Desktop folders
# Finally prints the list of all the versions of VsCode installed on the machine 
# and the path where it is installed

# Check in Downloads folder
if [ -d ~/Downloads ]; then
    for file in ~/Downloads/*; do
        if [[ $file == *"Visual Studio Code"* ]]; then
            echo "Visual Studio Code found in Downloads folder"
            echo "Path: $file"
        fi
    done
fi

# Check in Applications folder
if [ -d /Applications ]; then
    for file in /Applications/*; do
        if [[ $file == *"Visual Studio Code"* ]]; then
            echo "Visual Studio Code found in Applications folder"
            echo "Path: $file"
        fi
    done
fi

# Check in Desktop folder

if [ -d ~/Desktop ]; then
    for file in ~/Desktop/*; do
        if [[ $file == *"Visual Studio Code"* ]]; then
            echo "Visual Studio Code found in Desktop folder"
            echo "Path: $file"
        fi
    done
fi


