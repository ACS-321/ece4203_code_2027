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
export IO_NORTH_PINS = sg13g2_IOPad_q4 sg13g2_IOPad_q5 sg13g2_IOPad_q6 sg13g2_IOPad_q7
export IO_EAST_PINS  = sg13g2_IOPadVdd_inst sg13g2_IOPadVss_inst sg13g2_IOPad_q2 sg13g2_IOPad_q3
export IO_SOUTH_PINS = sg13g2_IOPad_clk sg13g2_IOPad_rst_n sg13g2_IOPad_en sg13g2_IOPad_up
export IO_WEST_PINS  = sg13g2_IOPad_q0 sg13g2_IOPad_q1 sg13g2_IOPadIOVss_inst sg13g2_IOPadIOVdd_inst

export PDN_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/pdn.tcl

export MAX_ROUTING_LAYER = TopMetal2
export PLACE_DENSITY     = 0.65
export TNS_END_PERCENT   = 100
