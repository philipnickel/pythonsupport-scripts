#!/bin/bash

# Copyright 2023
# Python Installation Support
# The Technical University of Denmark

_prefix="PYS:"

echo "$_prefix Uninstalling Python installations"

echo "$_prefix Deleting Python in $HOME/Library/Python"
sudo rm -rf ~/Library/Python

echo "$_prefix Deleting Python in /Application/Python"
sudo rm -rf /Applications/Python*

echo "$_prefix Deleting Python in /Library/Frameworks/Python.framework"
sudo rm -rf /Library/Frameworks/Python.framework

# Note: We don't remove system Python executables as they may be required by macOS

echo "$_prefix Python uninstall completed"