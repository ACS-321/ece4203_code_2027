// ECE4203 testbench for riscvsingle (from cvw/examples/verilog/riscvsingle,
// MIT license, see riscvsingle.sv). The instruction ROM (irom) and data memory
// (lsu) are the original behavioral models, now outside the core.
// Expect "Simulation succeeded" when 25 is written to address 100.

/* verilator lint_off COMBDLY */
/* verilator lint_off INITIALDLY */
/* verilator lint_off STMTDLY */

module testbench();
  logic        clk;
  logic        reset;
  logic [31:0] WriteData, IEUAdr;
  logic        MemWrite;
  logic [31:0] PC, Instr, ReadData;

  // instantiate device to be tested; memories are behavioral models outside it
  riscvsingle dut(.clk, .reset, .PC, .Instr, .MemWrite, .IEUAdr, .WriteData, .ReadData);
  irom imem(PC, Instr);
  lsu  dmem(.clk, .MemWrite, .IEUAdr, .WriteData, .ReadData);

  // waveform (make wave)
`ifdef VCD
  initial begin
    $dumpfile("riscvsingle.vcd");
    $dumpvars(0, testbench);
  end
`endif

  // initialize test
  initial begin
      reset <= 1; # 22; reset <= 0;
  end

  // generate clock to sequence tests
  always begin
      clk <= 1; # 5; clk <= 0; # 5;
  end

  // check results
  always @(negedge clk) begin
      if(MemWrite) begin
        if(IEUAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
          $stop;
        end else if (IEUAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
  end
endmodule

module irom(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("riscvtest.memfile",RAM);

  assign rd = RAM[a[7:2]]; // word aligned
endmodule

module lsu(
  input  logic        clk, MemWrite,
  input  logic [31:0] IEUAdr, WriteData,
  output logic [31:0] ReadData);

  logic [31:0] RAM[63:0];

  assign ReadData = RAM[IEUAdr[7:2]]; // word aligned

  always_ff @(posedge clk)
    if (MemWrite) RAM[IEUAdr[7:2]] <= WriteData;
endmodule

