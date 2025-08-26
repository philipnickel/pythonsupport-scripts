#!/bin/bash
# Test installer script for MacOS_DEV branch
# Runs the main DTU installer but from this fork/branch for testing

export REMOTE_PS="philipnickel/pythonsupport-scripts"
export BRANCH_PS="MacOS_DEV"

echo "Testing DTU Python Support installer from branch: $BRANCH_PS"
echo "Repository: $REMOTE_PS"
echo ""

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/install.sh)"