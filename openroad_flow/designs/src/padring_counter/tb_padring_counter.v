// Testbench: drive the chip pins (pads), check the counter through the pad cells.
//   iverilog -g2012 -o tb tb_padring_counter.v padring_counter.v \
//       $FLOW_HOME/platforms/ihp-sg13g2/verilog/sg13g2_io.v && vvp tb
`timescale 1ns/1ps
module tb;
  reg  clk_r = 0, rst_n_r = 0, en_r = 0, up_r = 1;
  wire clk = clk_r, rst_n = rst_n_r, en = en_r, up = up_r;  // inout pins need nets
  wire [7:0] q;
  padring_counter_top dut(.clk_PAD(clk), .rst_n_PAD(rst_n), .en_PAD(en), .up_PAD(up),
    .q0_PAD(q[0]), .q1_PAD(q[1]), .q2_PAD(q[2]), .q3_PAD(q[3]),
    .q4_PAD(q[4]), .q5_PAD(q[5]), .q6_PAD(q[6]), .q7_PAD(q[7]));
  always #5 clk_r = ~clk_r;
  initial begin
    #12 rst_n_r = 1; en_r = 1;
    repeat (10) @(posedge clk); #1;
    if (q !== 8'd10) begin $display("FAIL counting up: q=%0d", q); $finish; end
    up_r = 0;
    repeat (3) @(posedge clk); #1;
    if (q !== 8'd7) begin $display("FAIL counting down: q=%0d", q); $finish; end
    $display("PASS: counted up to 10 and down to %0d through the pad cells", q);
    $finish;
  end
endmodule
