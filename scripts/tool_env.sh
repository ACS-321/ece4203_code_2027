#!/bin/bash

source /OpenROAD-flow-scripts/env.sh

oss_cad_run() {
    (source /opt/oss-cad-suite/environment && "$@")
}

alias iverilog='oss_cad_run iverilog'
alias gtkwave='oss_cad_run gtkwave'
alias oss_yosys='oss_cad_run yosys'

alias klayout='klayout -e'

