# ECE4203 Assignment 2: Seeing delay

**RTL vs. gate-level simulation, glitches, and static timing analysis**

An RTL simulation has no delays: when the clock ticks, the adder's output jumps to
the right answer in zero time. The real circuit is a network of gates, each with a
delay. After the clock edge the output *ripples*: bits change, change back
(**glitches**), and finally settle. Static timing analysis (STA) predicts the worst
settling time without simulating anything. In this assignment you watch the RTL and
the gate-level netlist side by side, measure the settling, check it against
OpenSTA's critical path, and then speed up the clock until the circuit breaks.

**Time:** about 3–4 hours. **Prerequisite:** Lab 1 (and ideally Assignment 1).

## Learning objectives

After this assignment you can:
1. Explain the difference between zero-delay (RTL) and delay-annotated (gate-level + SDF) simulation.
2. Find and explain glitches in a gate-level waveform.
3. Read an OpenSTA path report: startpoint, endpoint, cell delays, arrival, required time and slack. Find that path in the netlist and in the waveform.
4. Predict from STA when a circuit fails, test the prediction in simulation, and explain where the two disagree.

## How the comparison works

```bash
cd lab1
make compare WIDTH=8 PERIOD=4
gtkwave results/compare_8_4.vcd sim/compare.gtkw &      # in the desktop
```

`make compare` synthesizes the adder for `PERIOD`, runs OpenSTA (which also writes
an SDF file with every cell's delay), and builds a testbench, `sim/tb_compare.v`,
that contains **two adders fed the same inputs**:

| Instance | What it is | Delays |
|---|---|---|
| `rtl` | `rtl/registered_adder.v` | none (zero-delay) |
| `gl` | the synthesized netlist `results/netlist_8_4.v`, timed by `scripts/sdf_inject.py` | each cell's delay from the SDF (`results/netlist_8_4.sdf`) |

- A new input vector is applied on every falling clock edge. The first vectors are chosen to create long carries (MAX + 1, 0101… + 1010… + 1, …); then come 24 random vectors.
- `result_rtl` / `result_gl` are the adders' outputs, i.e. the **D inputs of the output flip-flops**. That's where the critical path ends.
- Just before every rising edge, the testbench compares `sum_rtl` with `sum_gl` and prints `MISMATCH` lines and a summary.
- `SIM_PERIOD` runs the *same* netlist (built and timed for `PERIOD`) with a different clock in simulation: `make compare WIDTH=8 PERIOD=4 SIM_PERIOD=1.2`.
- Wire delays are zero in this flow (the SDF comes from synthesis, before place and route), in both STA and the simulation.

In GTKWave: right-click `result_gl` → **Data Format → Binary**, then **Expand** to see the bits separately. Use the primary marker (left click) and the secondary marker (middle click, or Ctrl+left click) to measure time differences.

## Part A: Zero delay vs. real delay (W = 8, T = 4 ns)

1. Run `make compare WIDTH=8 PERIOD=4`. Does the summary say `MATCH`? What does `results/sta_w8p4.log` report as the worst slack?
2. Zoom in on the cycle where the inputs change from **MAX + 0** to **MAX + 1** (`a = ff`, `b = 00 → 01`). Screenshot `result_rtl` and `result_gl` over that cycle.
   - Describe what `result_gl` does after the rising edge, bit by bit.
   - How many distinct values does it pass through before settling?
3. **Glitches.** Find a bit of `result_gl` that changes more than once in one cycle and ends where it started, or one that briefly takes a wrong value. Explain the cause using the adder structure: two paths into the same gate with different delays.
4. Does any of this ripple and glitching reach `sum_gl`? Why not? Your answer should explain why we register outputs.

## Part B: Matching simulation to STA

5. Open `results/sta_w8p4.log` and find the setup (max) path report. Write down:
   - the startpoint and endpoint;
   - for each stage: the cell, its incremental delay, and the cumulative arrival;
   - the data arrival time, the data required time, and the slack.
6. Find the endpoint bit in the waveform (for example `result_gl[8]` if the endpoint is the `cout` flip-flop). Over all simulated cycles, measure the **latest** time that bit settles after a rising clock edge. Compare with the STA data arrival time.
   - Which is larger, and by how much?
   - Give at least two reasons they can differ. Think about which input patterns STA assumes versus which ones you applied, rising vs. falling transitions, and the flip-flop's clock-to-Q time.
7. **Follow the path.** The path report names the cell instances (e.g. `_123_`). Find two of them in `results/netlist_8_4.v`, and find their output nets under `gl` in GTKWave's signal tree. Add them to the waveform, and show for one cycle that the transition really moves through them in the order STA lists, with roughly the delays STA lists.
8. Now run **W = 32, T = 4 ns** (`make compare WIDTH=32 PERIOD=4`).
   - What do STA's slack and the comparison summary say? Do they agree?
   - Find the mismatching cycle(s) in the waveform: which input vector, and which bits of `sum_gl` were wrong?
   - How did the critical path and its arrival time change from W = 8? Is that consistent with your delay per bit from Assignment 1?

## Part C: Speeding up the clock until it breaks

Keep the 8-bit netlist built for 4 ns, but clock it faster in simulation:

```bash
for s in 2 1.5 1.2 1.0 0.8 0.6; do make compare WIDTH=8 PERIOD=4 SIM_PERIOD=$s; done
```

9. **Predict first.** From the STA report at 4 ns, what is the shortest period this netlist should work at? Remember the flip-flop's setup time: required time = period − setup.
10. Run the loop. For each `SIM_PERIOD`, record MATCH or the number of mismatching cycles. At what period does the simulation start failing? Compare with your prediction from question 9.
11. In the first failing run, open the waveform and find the first `MISMATCH` cycle.
    - Show that the output flip-flop sampled `result_gl` *before it settled*. Which bits were wrong: the low bits or the high bits? Why?
    - Did every cycle fail, or only some? Which input vectors failed, and why those?
12. The simulation can keep passing at periods slightly shorter than STA allows, or fail at slightly longer ones. Explain both possibilities. Hint: the sky130 flip-flop models here have no setup/hold checks (`FUNCTIONAL`), and STA uses worst-case input patterns.

## Part D (optional, +10): A different netlist for a different clock

13. Now let synthesis know about the faster clock: `make compare WIDTH=8 PERIOD=1.2`, which re-synthesizes and re-times for 1.2 ns.
    - Does it pass? Compare its STA arrival time, cell count and area with the netlist built for 4 ns.
    - What did synthesis change in the circuit to make it faster? Look at the cell list in `results/yosys_8_1.2.log` and the path report.

## What to hand in

A PDF report, no more than 8 pages plus an appendix:
- Waveform screenshots for questions 2, 3, 7 and 11: markers placed, signals labeled, time scale readable.
- The STA path table (question 5) and your measured-vs-STA comparison (questions 6 and 8).
- The `SIM_PERIOD` table (question 10) with your prediction marked.
- Answers to questions 1–12 (and 13 if you do Part D).

### Grading (100, +10)

| | Points |
|---|---|
| Part A: ripple and glitch observed and explained; why outputs are registered (Q1–4) | 25 |
| Part B: path report read correctly; sim vs STA measured and explained; path followed in the waveform (Q5–8) | 35 |
| Part C: prediction, failure threshold, failing cycle explained, sim vs STA pessimism (Q9–12) | 30 |
| Report quality: readable screenshots with markers, units, a clear table | 10 |
| Part D (optional) | +10 |
