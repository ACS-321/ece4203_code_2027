// ECE4203 Lab 1 — RTL vs. gate-level comparison (Assignment 2)
//
// Run:
//   make compare WIDTH=8 PERIOD=4
//   gtkwave results/compare_8_4.vcd sim/compare.gtkw &
//
// Two copies of the registered adder get exactly the same inputs:
//   rtl : the RTL (rtl/registered_adder.v, renamed registered_adder_rtl)
//         -> zero-delay: result changes at the clock edge, in one step
//   gl  : the synthesized netlist with cell delays from OpenSTA's SDF
//         -> result ripples, and can glitch, before it settles
//
// A new input vector is applied every cycle (on the falling edge). Because both
// inputs and outputs are registered, the adder's critical path runs from the
// input flops (a_r/b_r/cin_r) through the adder to the output flops' D pins,
// which are the `result` bits. Compare result_gl's settling time after each
// rising edge with the data arrival time in results/sta_w<W>p<P>.log.
//
// sum_rtl and sum_gl are compared just before every rising edge. If the period
// is shorter than the critical path, the output flops in `gl` capture a value
// that has not settled, and the sums stop matching.

`timescale 1ns/1ps

`ifndef WIDTH
`define WIDTH 8
`endif
`ifndef PERIOD
`define PERIOD 4
`endif

module tb_compare;

  parameter WIDTH      = `WIDTH;
  parameter CLK_PERIOD = `PERIOD;

  reg              clk, rst_n;
  reg  [WIDTH-1:0] a, b;
  reg              cin;

  wire [WIDTH-1:0] sum_rtl, sum_gl;
  wire             cout_rtl, cout_gl;
  wire [WIDTH:0]   result_rtl, result_gl;   // adder outputs = output flops' D pins

  registered_adder_rtl #(.WIDTH(WIDTH)) rtl (
      .clk(clk), .rst_n(rst_n), .a(a), .b(b), .cin(cin),
      .sum(sum_rtl), .cout(cout_rtl), .result(result_rtl));

  // The netlist was synthesized for one WIDTH, so it has no parameter.
  registered_adder gl (
      .clk(clk), .rst_n(rst_n), .a(a), .b(b), .cin(cin),
      .sum(sum_gl), .cout(cout_gl), .result(result_gl));

  initial begin
`ifdef VCD_FILE
    $dumpfile(`VCD_FILE);
`else
    $dumpfile("results/compare.vcd");
`endif
    $dumpvars(0, tb_compare);
  end

  initial clk = 0;
  always #(CLK_PERIOD / 2.0) clk = ~clk;

  // ---- Compare the registered outputs just before each rising edge ----
  integer cycle = 0, compared = 0, mismatches = 0;
  always @(posedge clk) begin
    cycle = cycle + 1;
    #(CLK_PERIOD * 0.95);
    if (rst_n && cycle > 5) begin
      compared = compared + 1;
      if (sum_gl !== sum_rtl || cout_gl !== cout_rtl) begin
        mismatches = mismatches + 1;
        $display("MISMATCH t=%0.3f ns  rtl: cout=%0d sum=%h   gl: cout=%0d sum=%h",
                 $realtime, cout_rtl, sum_rtl, cout_gl, sum_gl);
      end
    end
  end

  // ---- Stimulus: one new vector per cycle, applied on the falling edge ----
  localparam [WIDTH-1:0] ZERO = {WIDTH{1'b0}};
  localparam [WIDTH-1:0] ONES = {WIDTH{1'b1}};
  localparam [WIDTH-1:0] ONE  = {{(WIDTH-1){1'b0}}, 1'b1};
  localparam [WIDTH-1:0] ALT0 = {(WIDTH+1)/2{2'b01}};   // ...0101
  localparam [WIDTH-1:0] ALT1 = {(WIDTH+1)/2{2'b10}};   // ...1010

  task apply(input [WIDTH-1:0] in_a, input [WIDTH-1:0] in_b, input in_cin);
    begin
      @(negedge clk);
      a = in_a; b = in_b; cin = in_cin;
    end
  endtask

  integer i, seed = 4203;
  initial begin
    rst_n = 0; a = ZERO; b = ZERO; cin = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;

    apply(ZERO, ZERO, 1'b0);   // 0 + 0
    apply(ONES, ZERO, 1'b0);   // MAX + 0
    apply(ONES, ONE,  1'b0);   // MAX + 1    : carry ripples through every bit
    apply(ZERO, ZERO, 1'b0);   // back to 0  : every result bit falls
    apply(ONES, ZERO, 1'b1);   // MAX + cin  : carry from cin through every bit
    apply(ALT0, ALT1, 1'b0);   // 0101 + 1010: no carries at all
    apply(ALT0, ALT1, 1'b1);   // ... + cin  : full-length carry again
    apply(ONES, ONES, 1'b1);   // MAX + MAX + 1
    for (i = 0; i < 24; i = i + 1)
      apply($random(seed), $random(seed), $random(seed));
    apply(ZERO, ZERO, 1'b0);

    repeat (4) @(posedge clk);
    #(CLK_PERIOD);
    if (mismatches == 0)
      $display("\nMATCH: gate-level sums equal RTL on all %0d compared cycles (WIDTH=%0d, PERIOD=%0g ns).",
               compared, WIDTH, CLK_PERIOD);
    else
      $display("\n%0d of %0d cycles differ: the gate-level adder misses the %0g ns clock.",
               mismatches, compared, CLK_PERIOD);
    $finish;
  end

endmodule
