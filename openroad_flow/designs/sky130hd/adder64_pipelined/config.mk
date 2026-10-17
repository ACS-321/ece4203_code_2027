export DESIGN_NAME = adder64_pipelined
export PLATFORM    = sky130hd

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/adder64_pipelined.v
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

# Adders degrade GCD
export ADDER_MAP_FILE :=

# Fixed die: 196 I/O pins need a ~270 um perimeter, and io_constraints.tcl places
# pins up to 120 um along each edge. At the 2.0 ns clock, timing repair grows the
# 64-bit adder to ~14,500 um^2 of cells, so the core is 190 x 190 um (~40%).
export DIE_AREA  = 0 0 200 200
export CORE_AREA = 5 5 195 195
export TNS_END_PERCENT = 100
export EQUIVALENCE_CHECK   ?=   0
export REMOVE_CELLS_FOR_EQY = sky130_fd_sc_hd__tapvpwrvgnd*

export IO_CONSTRAINTS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/io_constraints.tcl
