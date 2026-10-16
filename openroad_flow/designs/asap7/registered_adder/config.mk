# Same RTL as ../../sky130hd/registered_adder, on the 7 nm predictive asap7 PDK.
# The sky130hd pin constraints (io_constraints.tcl) are in absolute microns sized
# for a sky130 die, so they're omitted here and pins are placed automatically.
export DESIGN_NAME     = registered_adder
export DESIGN_NICKNAME = registered_adder
export PLATFORM        = asap7

export VERILOG_FILES = $(DESIGN_HOME)/src/registered_adder/registered_adder.v
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/registered_adder/constraint.sdc

export CORE_UTILIZATION = 50
export CORE_MARGIN      = 2
export TNS_END_PERCENT  = 100
