# ECE4203 Lab 1 — Yosys synthesis script (sky130hd)
#
# Called by the Makefile as:
#   WIDTH=<N> LIBERTY=<path> yosys -D WIDTH=<N> -l results/yosys_<N>.log synth/synth.tcl
#
# Outputs:
#   results/netlist_<WIDTH>.v    — technology-mapped Verilog netlist
#   results/yosys_<WIDTH>.log    — full log with stat report
yosys -import
# ---- Read RTL ----
read_verilog -D WIDTH=$::env(WIDTH) rtl/registered_adder.v
chparam -set WIDTH $::env(WIDTH)
# ---- Elaborate ----
# -flatten exposes the full adder cone as a single logic cone so that
# ABC can see carry-chain structure across what were module boundaries.
synth -top registered_adder -flatten

# ---- FF mapping ----
# Maps Yosys internal $_DFF_P_ / $_DFF_PN0_ primitives to liberty cells
# (e.g. sky130_fd_sc_hd__dfxtp_1).
# Must run BEFORE abc so ABC sees real cell timing for fanout/load.
dfflibmap -liberty $::env(LIBERTY)

# ---- Combinational technology mapping ----
# ABC maps the adder carry cone to sky130hd standard cells.
# For wider adders it often selects sky130_fd_sc_hd__fah_1 (full adder)
# and sky130_fd_sc_hd__fahcin_1 carry cells — students should look for
# these in the netlist.
abc -liberty $::env(LIBERTY)

# ---- Report ----
stat -liberty $::env(LIBERTY)

# ---- Write netlist ----
# -noattr strips Yosys metadata attributes so the file is clean Verilog
# that iverilog can compile directly alongside the sky130 cell models.
write_verilog -noattr results/netlist_$::env(WIDTH).v
