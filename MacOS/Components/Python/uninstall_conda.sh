#!/bin/bash
# @doc
# @name: Conda Uninstaller
# @description: Completely removes conda/miniconda installations from macOS
# @category: Python
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/uninstall_conda.sh)"
# @requirements: macOS system, existing conda installation
# @notes: Removes both Anaconda and Miniconda installations, cleans configuration files and PATH modifications
# @/doc



_prefix="PYS:"

echo "$_prefix Uninstalling conda/miniconda"

# if anaconda is installed, delete it
if [ -d ~/anaconda* ] ; then
    echo "$_prefix Found anaconda installation, removing..."
    source ~/anaconda3/bin/activate
    conda install anaconda-clean -y
    anaconda-clean -y
    conda deactivate
    rm -rf ~/anaconda*
    rm -rf ~/.anaconda_backup
    echo "$_prefix Anaconda removed"
fi

# if miniconda is installed, delete it
if [ -d ~/miniconda* ] ; then
    echo "$_prefix Found miniconda installation, removing..."
    rm -rf ~/miniconda*
    echo "$_prefix Miniconda removed"
fi

# Clean up shell configuration files
echo "$_prefix Cleaning up shell configuration..."

# Remove conda initialization from shell profiles
if [ -f ~/.bashrc ]; then
    sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' ~/.bashrc
fi

if [ -f ~/.zshrc ]; then
    sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' ~/.zshrc
fi

echo "$_prefix Conda/Miniconda uninstall completed"