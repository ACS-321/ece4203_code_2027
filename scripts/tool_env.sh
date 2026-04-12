#!/bin/bash

source /OpenROAD-flow-scripts/env.sh

oss_cad_run() {
    (source /opt/oss-cad-suite/environment && "$@")
}

export FLOW_HOME="/workspaces/ece4203_code/openroad_flow"
export YOSYS_EXE="/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys"
export OPENROAD_EXE="/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad"

alias iverilog='oss_cad_run iverilog'
alias gtkwave='oss_cad_run gtkwave'
alias oss_yosys='oss_cad_run yosys'

alias klayout='klayout -e'

alias cdhome='cd $HOME'
alias cdwork='cd /workspaces/ece4203_code'

KLAYOUT_PKG_DIR="$HOME/.klayout/salt"
REPO_PKG_DIR="/workspaces/ece4203_code/scripts/salt"

mkdir -p "$KLAYOUT_PKG_DIR"

for pkg in "$REPO_PKG_DIR"/*/; do
    pkg_name=$(basename "$pkg")
    if [ ! -d "$KLAYOUT_PKG_DIR/$pkg_name" ]; then
        echo "Installing KLayout package: $pkg_name"
        cp -r "$pkg" "$KLAYOUT_PKG_DIR/"
    fi
done
