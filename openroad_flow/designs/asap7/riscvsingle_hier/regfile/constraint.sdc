# asap7: times in ps. Same clock as the top level.
current_design regfile
set clk_period 1000
create_clock -name core_clock -period $clk_period [get_ports clk]
# Reads are combinational (A1/A2 -> RD1/RD2). Budget 30% of the cycle each side,
# so the abstract's timing model leaves room for the rest of the datapath.
set_input_delay  [expr $clk_period * 0.3] -clock core_clock [all_inputs -no_clocks]
set_output_delay [expr $clk_period * 0.3] -clock core_clock [all_outputs]
