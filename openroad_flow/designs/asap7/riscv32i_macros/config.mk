# ORFS's riscv32i (OSU single-cycle RV32I) whose data memory is four
# fakeram7_256x32 SRAM macros, with the macros placed BY HAND (macros.tcl).
# Compare with ORFS's own `make DESIGN=riscv32i PLATFORM=asap7`, where the
# RTL macro placer (RTLMP) chooses the positions.
export DESIGN_NAME     = riscv_top
export DESIGN_NICKNAME = riscv32i_macros
export PLATFORM        = asap7

export SYNTH_HIERARCHICAL      = 1
export SYNTH_MINIMUM_KEEP_SIZE = 10000

export VERILOG_FILES = $(sort $(wildcard $(FLOW_HOME)/designs/src/riscv32i/*.v))
export SDC_FILE      = $(FLOW_HOME)/designs/asap7/riscv32i/constraint.sdc

# The SRAM macro: abstract (LEF) for placement/routing, liberty for timing.
export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram7_256x32.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/NLDM/fakeram7_256x32.lib

# Fixed die so the hand placement below is meaningful (um).
export DIE_AREA  = 0 0 110 110
export CORE_AREA = 5 5 105 105

export MACRO_PLACEMENT_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/macros.tcl
# Keep-out ring around each macro: no standard cells within 4 um (x y).
export MACRO_PLACE_HALO    = 4 4

# Pins on the bottom edge only (same as ORFS riscv32i).
export IO_CONSTRAINTS = $(FLOW_HOME)/designs/asap7/riscv32i/io.tcl

export PLACE_DENSITY_LB_ADDON = 0.10
export TNS_END_PERCENT        = 100
export CTS_CLUSTER_SIZE       = 10
export CTS_CLUSTER_DIAMETER   = 50
