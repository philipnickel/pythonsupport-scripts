#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PS_REPO_URL="file://$SCRIPT_DIR"

export PS_FORGE_URL="file://$SCRIPT_DIR/release_assets/dtu-miniconda"



echo $PS_REPO_URL

bash "$SCRIPT_DIR/Core/Orchestration/install_all_macOS.sh"
