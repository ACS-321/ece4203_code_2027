#!/bin/bash
# Remove the FPGA-only parts of OSS CAD Suite (place & route, bitstream tools,
# device databases, programmers). ECE4203 is an ASIC course; this saves about 1 GB.
# Kept: yosys (+slang), iverilog, verilator, gtkwave, surfer, ghdl, cocotb,
# sby/eqy/mcy and the formal solvers, aiger tools, xdot.
#
# Usage: prune-oss-cad.sh /opt/oss-cad-suite
set -euo pipefail
root="${1:?usage: $0 <oss-cad-suite dir>}"
cd "$root"
before="$(du -sm . | cut -f1)"

fpga_globs=(
    'nextpnr-*'                                     # FPGA place & route
    'ice*' 'icebox_*' 'icesprog'                    # Lattice iCE40 (icestorm)
    'ecp*'                                          # Lattice ECP5 (trellis), ecpprog, ecpdap
    'prjoxide'                                      # Lattice Nexus
    'gowin_*'                                       # Gowin (apicula)
    'openFPGALoader' 'openocd' 'fujprog' 'dfu-*'    # programmers / JTAG
    'lsftdi' 'lsusb'
)
for dir in bin libexec; do
    for g in "${fpga_globs[@]}"; do
        # shellcheck disable=SC2086
        rm -rf "${dir:?}"/$g
    done
done
rm -rf share/nextpnr share/icebox share/trellis share/prjoxide \
       lib/python3.11/site-packages/apycula*
after="$(du -sm . | cut -f1)"
echo "prune-oss-cad: ${before} MB -> ${after} MB"
