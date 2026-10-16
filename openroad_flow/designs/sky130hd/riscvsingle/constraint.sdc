# sky130hd: times in ns. Single-cycle: one clock covers fetch, decode, register read, ALU and write-back.
current_design riscvsingle

set clk_name core_clock
set clk_port_name clk
set clk_period 10.0
set clk_io_pct 0.2

set clk_port [get_ports $clk_port_name]
create_clock -name $clk_name -period $clk_period $clk_port

# The memories outside the block are modeled as I/O delays on a virtual clock.
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 0.5 [get_clocks $clk_name]
set_clock_latency 0.5 [get_clocks $clk_io_name]

set non_clock_inputs [all_inputs -no_clocks]
set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
