# IHP SG13G2: times in ns. The clock enters through a pad, so it is defined on
# the pad cell's core-side pin (p2c), as in the ORFS reference design.
current_design padring_counter_top
set clk_period 10.0
create_clock [get_pins sg13g2_IOPad_clk/p2c] -name clk_core -period $clk_period
set_ideal_network [get_pins sg13g2_IOPad_clk/p2c]
create_clock -name vclk_core -period $clk_period
set_clock_uncertainty 0.15 [get_clocks clk_core]

set_driving_cell -lib_cell sg13g2_IOPadIn -pin pad [get_ports {clk_PAD rst_n_PAD en_PAD up_PAD}]
set_input_delay  4.0 -clock vclk_core [get_ports {rst_n_PAD en_PAD up_PAD}]
set_output_delay 4.0 -clock vclk_core [get_ports {q*_PAD}]
set_load -pin_load 5 [all_outputs]
