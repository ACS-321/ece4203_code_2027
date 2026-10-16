# riscvsingle with its 31x32 register file HARDENED as a separate block:
#   1. ORFS runs ./regfile/config.mk through the whole flow and writes an
#      abstract of it: LEF (outline + pins + blockages), liberty (timing model)
#      and GDS (results/asap7/riscvsingle_hier_regfile/base/).
#   2. The top level then treats `regfile` as a macro, like an SRAM.
# Same RTL as ../riscvsingle (flat), so the two can be compared directly.
export DESIGN_NAME     = riscvsingle
export DESIGN_NICKNAME = riscvsingle_hier
export PLATFORM        = asap7

export VERILOG_FILES = $(DESIGN_HOME)/src/riscvsingle/riscvsingle.sv
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/riscvsingle/constraint.sdc

export SYNTH_HIERARCHICAL = 1
export BLOCKS             = regfile

export CORE_UTILIZATION       = 40
export CORE_MARGIN            = 2
export PLACE_DENSITY_LB_ADDON = 0.10
export MACRO_PLACE_HALO       = 2 2
export RTLMP_MIN_CHANNEL_SIZE = 6 6
export TNS_END_PERCENT        = 100
