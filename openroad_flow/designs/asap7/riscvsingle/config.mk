# Harris single-cycle RV32I subset, core only (see ../../sky130hd/riscvsingle).
export DESIGN_NAME     = riscvsingle
export DESIGN_NICKNAME = riscvsingle
export PLATFORM        = asap7

export VERILOG_FILES = $(DESIGN_HOME)/src/riscvsingle/riscvsingle.sv
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/riscvsingle/constraint.sdc

export CORE_UTILIZATION       = 55
export CORE_MARGIN            = 2
export PLACE_DENSITY_LB_ADDON = 0.10
export TNS_END_PERCENT        = 100
