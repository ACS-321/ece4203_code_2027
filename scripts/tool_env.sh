#!/bin/bash

source /OpenROAD-flow-scripts/env.sh

# Repo root, derived from this file's location, so the repo can have any name.
ECE4203_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# FLOW_HOME must stay the ORFS flow dir (set by env.sh); our designs live here:
export ECE4203_FLOW="${ECE4203_REPO}/openroad_flow"

# OSS CAD Suite tools (iverilog, gtkwave, verilator, ...) are on PATH after the
# ORFS tools; `yosys` is the ORFS build. The OSS CAD yosys is `oss-yosys`.
alias oss_yosys='oss-yosys'

alias klayout='klayout -e'

alias cdhome='cd $HOME'
alias desktop='bash "${ECE4203_REPO}/scripts/desktop.sh"'
alias cdwork='cd "${ECE4203_REPO}"'

KLAYOUT_PKG_DIR="$HOME/.klayout/salt"
REPO_PKG_DIR="${ECE4203_REPO}/scripts/salt"

mkdir -p "$KLAYOUT_PKG_DIR"

for pkg in "$REPO_PKG_DIR"/*/; do
    pkg_name=$(basename "$pkg")
    if [ ! -d "$KLAYOUT_PKG_DIR/$pkg_name" ]; then
        echo "Installing KLayout package: $pkg_name"
        cp -r "$pkg" "$KLAYOUT_PKG_DIR/"
    fi
done
