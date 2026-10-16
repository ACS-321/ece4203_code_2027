#!/bin/bash

source /OpenROAD-flow-scripts/env.sh

# Repo root, derived from this file's location, so the repo can have any name.
ECE4203_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

oss_cad_run() {
    (source /opt/oss-cad-suite/environment && "$@")
}

export FLOW_HOME="${ECE4203_REPO}/openroad_flow"
export YOSYS_EXE="/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys"
export OPENROAD_EXE="/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad"

alias iverilog='oss_cad_run iverilog'
alias gtkwave='oss_cad_run gtkwave'
alias oss_yosys='oss_cad_run yosys'

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
