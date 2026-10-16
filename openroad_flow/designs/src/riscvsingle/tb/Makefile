# RTL simulation of riscvsingle with the original test program (riscvtest.S).
#   make sim     expect "Simulation succeeded" (25 written to address 100)
#   make wave    same, then open the waveform in gtkwave
SHELL := /bin/bash
RTL := ../riscvsingle.sv

.PHONY: sim wave clean
sim: riscvsingle_tb.vvp
	vvp -n $< | tee sim.log
	@grep -q "Simulation succeeded" sim.log && echo ">>> riscvsingle RTL sim PASSED <<<" \
	  || { echo ">>> riscvsingle RTL sim FAILED <<<"; exit 1; }

riscvsingle_tb.vvp: riscvsingle_tb.sv $(RTL) riscvtest.memfile
	iverilog -g2012 -D VCD -o $@ riscvsingle_tb.sv $(RTL) 2>&1 | grep -v "sorry: constant selects" || true
	@test -f $@

wave: sim
	gtkwave riscvsingle.vcd &

clean:
	rm -f riscvsingle_tb.vvp sim.log riscvsingle.vcd
