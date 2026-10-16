# Pad-ring teaching example on IHP SG13G2 (130 nm), adapted from ORFS
# designs/ihp-sg13g2/i2c-gpio-expander. The I/O ring is built in floorplan by the
# platform's pad.tcl (FOOTPRINT_TCL): make_io_sites, place_pads, place_corners,
# place_io_fill, connect_by_abutment, place_bondpad.
export DESIGN_NAME     = padring_counter_top
export DESIGN_NICKNAME = padring_counter
export PLATFORM        = ihp-sg13g2

export VERILOG_FILES  = $(DESIGN_HOME)/src/padring_counter/padring_counter.v
export VERILOG_FILES += $(PLATFORM_DIR)/verilog/sg13g2_io.v
export SDC_FILE       = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

# Same die/core as the ORFS reference (so its seal ring fits): 1.05 mm square die,
# ~350 um core in the middle. The tiny core logic leaves the core mostly empty;
# the die size here is set by the pads, i.e. the design is "pad limited".
export DIE_AREA  = 0.0 0.0 1050.24 1050.84
export CORE_AREA = 351.36 351.54 699.84 699.3
export SEAL_GDS  = $(FLOW_HOME)/designs/ihp-sg13g2/i2c-gpio-expander/sealring.gds.gz

export FOOTPRINT_TCL = $(PLATFORM_DIR)/pad.tcl
# Pad order on each side (instance names from padring_counter.v), counter-clockwise.
export IO_NORTH_PINS = pad_q4 pad_q5 pad_q6 pad_q7
export IO_EAST_PINS  = pad_vdd pad_vss pad_q2 pad_q3
export IO_SOUTH_PINS = pad_clk pad_rst_n pad_en pad_up
export IO_WEST_PINS  = pad_q0 pad_q1 pad_iovss pad_iovdd

export PDN_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/pdn.tcl

export MAX_ROUTING_LAYER = TopMetal2
export PLACE_DENSITY     = 0.65
export TNS_END_PERCENT   = 100
