// ECE4203 pad-ring example (IHP SG13G2, 130 nm): an 8-bit up/down counter core
// inside a ring of 16 I/O pads. Adapted from ORFS designs/ihp-sg13g2/i2c-gpio-expander.
//
//   chip pins (*_PAD) <-> pad cells (sg13g2_IOPad*) <-> core (counter8)
//
// Pad cells: sg13g2_IOPadIn       pad -> p2c (pad-to-core)
//            sg13g2_IOPadOut4mA   c2p (core-to-pad) -> pad, 4 mA driver
//            sg13g2_IOPadVdd/Vss       core supply (1.2 V) pads
//            sg13g2_IOPadIOVdd/IOVss   pad-ring I/O supply (3.3 V) pads
// The instance names are what config.mk lists in IO_NORTH/EAST/SOUTH/WEST_PINS.
// They must start with sg13g2_IOPad: the platform pad.tcl puts a bond pad on
// every instance matching sg13g2_IOPad*.

module counter8 (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       en,
  input  wire       up,
  output reg  [7:0] q
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n)  q <= 8'd0;
    else if (en) q <= up ? q + 8'd1 : q - 8'd1;
endmodule

module padring_counter_top (
  inout wire clk_PAD, rst_n_PAD, en_PAD, up_PAD,
  inout wire q0_PAD, q1_PAD, q2_PAD, q3_PAD, q4_PAD, q5_PAD, q6_PAD, q7_PAD
);
  wire       clk, rst_n, en, up;
  wire [7:0] q;

  sg13g2_IOPadIn sg13g2_IOPad_clk   (.pad(clk_PAD),   .p2c(clk));
  sg13g2_IOPadIn sg13g2_IOPad_rst_n (.pad(rst_n_PAD), .p2c(rst_n));
  sg13g2_IOPadIn sg13g2_IOPad_en    (.pad(en_PAD),    .p2c(en));
  sg13g2_IOPadIn sg13g2_IOPad_up    (.pad(up_PAD),    .p2c(up));

  sg13g2_IOPadOut4mA sg13g2_IOPad_q0 (.c2p(q[0]), .pad(q0_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q1 (.c2p(q[1]), .pad(q1_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q2 (.c2p(q[2]), .pad(q2_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q3 (.c2p(q[3]), .pad(q3_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q4 (.c2p(q[4]), .pad(q4_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q5 (.c2p(q[5]), .pad(q5_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q6 (.c2p(q[6]), .pad(q6_PAD));
  sg13g2_IOPadOut4mA sg13g2_IOPad_q7 (.c2p(q[7]), .pad(q7_PAD));

  // Supply pads have no signal ports; (* keep *) stops synthesis removing them.
  (* keep *) sg13g2_IOPadVdd   sg13g2_IOPadVdd_inst   ();
  (* keep *) sg13g2_IOPadVss   sg13g2_IOPadVss_inst   ();
  (* keep *) sg13g2_IOPadIOVdd sg13g2_IOPadIOVdd_inst ();
  (* keep *) sg13g2_IOPadIOVss sg13g2_IOPadIOVss_inst ();

  counter8 core (.clk(clk), .rst_n(rst_n), .en(en), .up(up), .q(q));
endmodule
