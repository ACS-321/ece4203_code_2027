# The hardened block. ORFS finds this file because BLOCKS = regfile in ../config.mk.
export DESIGN_NAME         = regfile
export TOP_DESIGN_NICKNAME = riscvsingle_hier
export DESIGN_NICKNAME     = $(TOP_DESIGN_NICKNAME)_$(DESIGN_NAME)
export PLATFORM            = asap7

export VERILOG_FILES = $(DESIGN_HOME)/src/riscvsingle/riscvsingle.sv
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(TOP_DESIGN_NICKNAME)/regfile/constraint.sdc

export CORE_UTILIZATION  = 50
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN       = 2
export PLACE_DENSITY     = 0.65
export PLACE_PINS_ARGS   = -annealing

# The block only uses M1-M5, so the top level can route over it on M6+.
export MAX_ROUTING_LAYER = M5
# Block-style power grid that the top-level grid connects to.
export PDN_TCL = $(PLATFORM_DIR)/openRoad/pdn/BLOCK_grid_strategy.tcl
