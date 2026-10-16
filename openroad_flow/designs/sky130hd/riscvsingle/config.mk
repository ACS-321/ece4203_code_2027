# Harris single-cycle RV32I subset (cvw/examples/verilog/riscvsingle), core only:
# instruction and data memories are outside the block (see src/riscvsingle).
export DESIGN_NAME     = riscvsingle
export DESIGN_NICKNAME = riscvsingle
export PLATFORM        = sky130hd

export VERILOG_FILES = $(DESIGN_HOME)/src/riscvsingle/riscvsingle.sv
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/riscvsingle/constraint.sdc

# ~3.7k cells, mostly the 31x32 register file (edfxtp flops).
export CORE_UTILIZATION       = 45
export PLACE_DENSITY_LB_ADDON = 0.20
export TNS_END_PERCENT        = 100
