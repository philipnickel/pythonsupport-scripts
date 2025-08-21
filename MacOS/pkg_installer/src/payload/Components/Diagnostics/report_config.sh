#!/bin/bash
# DTU Python Diagnostics - Report Configuration
# This file contains global settings for the diagnostic report generator

# Global timeout setting (in seconds)
# Default timeout for individual diagnostic scripts
DEFAULT_GLOBAL_TIMEOUT=20

# Repository settings for manual command generation
# These settings control where manual run commands point to
REPO_OWNER="philipnickel"
REPO_NAME="pythonsupport-scripts"
REPO_BRANCH="macos-components"

# Alternative: Use main branch
# REPO_BRANCH="main"

# Manual command template
# When a diagnostic times out, users get a curl command to run it manually
MANUAL_COMMAND_TEMPLATE="curl -s https://raw.githubusercontent.com/\${REPO_OWNER}/\${REPO_NAME}/\${REPO_BRANCH}/MacOS/Components/Diagnostics/\${SCRIPT_PATH} | bash"

# Parallel execution settings
MAX_PARALLEL_JOBS=5
PARALLEL_ENABLED=true

# Report display settings
SHOW_EXECUTION_TIMES=true
SHOW_CATEGORY_SUMMARIES=false

# Email settings
SUPPORT_EMAIL="pythonsupport@dtu.dk"

# Export variables for use in generate_report.sh
export DEFAULT_GLOBAL_TIMEOUT
export REPO_OWNER
export REPO_NAME  
export REPO_BRANCH
export MANUAL_COMMAND_TEMPLATE
export MAX_PARALLEL_JOBS
export PARALLEL_ENABLED
export SHOW_EXECUTION_TIMES
export SHOW_CATEGORY_SUMMARIES
export SUPPORT_EMAIL