# ECE4203 Lab 1 — Yosys synthesis script (sky130hd)
#
# Called by the Makefile as:
#   WIDTH=<N> PERIOD=<P> LIBERTY=<path> ABC_PERIOD_PS=<ps> \
#       yosys -l results/yosys_<N>_<P>.log -p "tcl synth/synth.tcl"
#
# Environment variables:
#   WIDTH          — adder bit width (e.g. 8)
#   PERIOD         — clock period in ns (e.g. 4.0) — used for output filename
#   LIBERTY        — path to sky130hd liberty file
#   ABC_PERIOD_PS  — combinational delay budget for ABC in picoseconds
#                    = (PERIOD * 1000) - FF_setup_ps
#                    tells ABC how aggressively to optimise for speed:
#                      tight → larger drive-strength cells, may restructure logic
#                      loose → smaller cells, optimises for area
#
# Outputs:
#   results/netlist_<WIDTH>_<PERIOD>.v   — technology-mapped netlist
#   results/yosys_<WIDTH>_<PERIOD>.log   — full log (written by Makefile -l flag)

yosys -import

# ---- Read RTL ----
read_verilog rtl/registered_adder.v
chparam -set WIDTH $::env(WIDTH)

# ---- Elaborate ----
# -flatten merges hierarchy so ABC sees the full carry cone as one
# logic network and can restructure it freely.
synth -top registered_adder -flatten

# ---- FF mapping ----
# Maps Yosys internal $_DFF_* primitives to sky130hd FF cells
# (e.g. sky130_fd_sc_hd__dfxtp_1).  Must run before abc so ABC
# accounts for FF input capacitance when sizing driver cells.
dfflibmap -liberty $::env(LIBERTY)

# ---- Combinational technology mapping ----
# -D <ps> sets the target combinational delay budget.
# ABC will try to meet this target by selecting appropriate cell
# sizes and logic structures.  Students can observe the effect by
# comparing netlists synthesised at different periods.
abc -liberty $::env(LIBERTY) -D $::env(ABC_PERIOD_PS)

# ---- Area / cell report ----
# Captured to results/yosys_<WIDTH>_<PERIOD>.log by the -l flag.
stat -liberty $::env(LIBERTY)

# ---- Write mapped netlist ----
# Filename includes both WIDTH and PERIOD so each (WIDTH, PERIOD)
# pair produces a distinct file and runs don't overwrite each other.
write_verilog -noattr results/netlist_$::env(WIDTH)_$::env(PERIOD).v
