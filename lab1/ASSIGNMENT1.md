# ECE4203 Assignment 1: How does an adder scale?

**Area, power and the cost of speed, from Lab 1's registered adder**

In Lab 1 you synthesized the registered adder (`rtl/registered_adder.v`) to sky130
standard cells with Yosys, timed it with OpenSTA, and simulated it. In this
assignment you sweep its **width** and its **clock period**, collect the results,
and build simple models from them: area per bit, power per bit, power per MHz,
and delay per bit. Your plots are the evidence for every claim you make.

**Time:** about 3–4 hours. Almost all of it is analysis; the tool runs take a few minutes.

## Learning objectives

After this assignment you can:
1. Run a parameter sweep with Yosys + OpenSTA and collect the results.
2. Fit a straight line to measured data, report its slope **with units**, and say over what range it's valid.
3. Separate a design's area and power into sequential (flip-flop) and combinational parts, and predict them from the cell library.
4. Explain why a tighter clock costs area and power, beyond just "more frequency".

## Background (read before you start)

The circuit is a `WIDTH`-bit adder whose inputs (`a`, `b`, `cin`) and outputs
(`sum`, `cout`) are all registered:

```
a,b,cin ──►[input FFs]──► adder (combinational) ──►[output FFs]──► sum,cout
             2W+1 flops        "result"                W+1 flops
```

- **Area.** Every bit needs three flip-flops (`a_r`, `b_r`, `sum`) plus its share of the adder. Look up the cell areas yourself in the liberty file (`$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib`, search for `cell ("sky130_fd_sc_hd__dfrtp_1")` and its `area`).
- **Timing.** Synthesis is told how fast the adder must be: `ABC_PERIOD_PS = PERIOD − 520 ps` (see `synth/synth.tcl`). With a loose target, ABC builds the smallest adder: a ripple-carry chain. With a tight target, it restructures and upsizes cells to shorten the carry path.
- **Power.** OpenSTA's `report_power` uses an activity of 0.2 on the inputs and 1.0 on the clock (see `synth/sta.tcl.template`). Dynamic power is roughly *P = α·C·V²·f*. Leakage doesn't depend on f.

## Setup

In your Codespace, from the repo:

```bash
cd lab1
make clean
make csv WIDTHS="4 8 16 24 32 48 64" PERIODS="1 2 4 8 16"
```

- `make csv` synthesizes and times all 35 design points (a few minutes) and writes **`results/summary.csv`**, one row per (width, period). The columns are described at the top of `scripts/collect_results.py`.
- `make summary` prints the same results as tables.

**Making the plots is part of the assignment.** Download `results/summary.csv` (right-click it in the VS Code file explorer → Download) and plot it with Excel or Google Sheets, or ask an AI assistant to write a plotting script for you. Either is fine, but:
- **Excel/Sheets:** use a scatter chart and a linear trendline with "display equation and R²". Or use `=SLOPE()`, `=INTERCEPT()` and `=RSQ()` over the range you choose.
- **AI:** include the prompt you used and the code it produced in the appendix. Check at least one slope by hand from two data points. You're responsible for the fit being right and for the range it's fitted over.

## Part A: Area per bit at a relaxed clock (T = 16 ns)

1. **Predict first.** From the liberty file, write down the area of `sky130_fd_sc_hd__dfrtp_1` and of the cells a ripple adder would use. Predict the area per bit of the *flip-flops alone*, and write down your guess for the whole design.
2. Plot `area_um2` vs `width` at T = 16 ns. Fit `area = m·W + c`. Report **m in µm²/bit**, c, and the R² (or the largest residual).
3. Do the same for `seq_area_um2` (flip-flops only). Compare its slope with your prediction from step 1. Explain the intercept: why isn't it 0?
4. What fraction of the area is flip-flops at W = 4 and at W = 64? What does that say about where "an adder's area" really goes in this design?

## Part B: The cost of speed

Synthesis builds a **different circuit for every period**. With a loose target it
makes the smallest adder that still fits the time budget. With a tight one it spends
area to go faster. The `arrival_ns` column is the delay of each circuit's worst path.

5. Add T = 8, 4, 2 and 1 ns to the area plot.
   - Which part of the area grows as the clock tightens: `seq_area_um2` or the rest (`area_um2 − seq_area_um2`)? Show both.
   - For W = 64, by how many percent does the *combinational* area grow from 16 ns to 1 ns?
   - Open `results/yosys_64_16.log` and `results/yosys_64_1.log`, compare the cell lists at the end, and say what synthesis changed.
6. Plot `arrival_ns` vs W for the netlists built at **T = 1 ns** (the fastest synthesis can make) and at **T = 16 ns**.
   - Fit a line to the T = 1 ns points. Report the **delay per bit in ps/bit**. Is the fastest adder synthesis found still a ripple adder (delay ∝ W), or something faster (∝ log W)?
   - Compare that slope with one full-adder carry stage in the liberty file: `sky130_fd_sc_hd__fa_1`, pin `CIN → COUT`, or `maj3_1`, at a typical slew and load.
   - Why do the T = 16 ns arrival times grow so much faster with W? Hint: look at T = 16 ns, W = 64. How close is the arrival time to the budget?
7. Make a table for **W = 32**: area, combinational area, arrival and WNS at T = 16, 8, 4, 2 and 1 ns.
   - Which periods does it actually meet (WNS ≥ 0)?
   - What's the fastest clock a 32-bit adder can run at in this flow, and what does that speed cost in area compared with 16 ns?
   - Some loose-period points fail timing by a small amount. Why can synthesis's estimate miss? (Hint: what does ABC know about wire loads and the 520 ps it subtracted?)

## Part C: Power

8. Plot `power_total_w` vs width at T = 4 ns and fit a line. Report **µW/bit**.
9. Plot power vs clock frequency (`freq_mhz`) for W = 16, 32 and 64, using all five periods. Fit `P = k·f + P0` for each width.
   - Report k (µW/MHz) and P0 (µW).
   - Compute the **energy per clock cycle per bit, k/W, in fJ/bit**. Is it about the same for every width?
   - What is P0 physically? Compare it with `power_leakage_w`.
10. Use `power_seq_w` and `power_comb_w` to say which part dominates the power, and by how much. Why do the flip-flops dominate even though the adder is "the interesting part"? (Hint: what is the activity on the clock pin, and how many flip-flops are there per bit?)
11. The circuit at T = 1 ns is bigger than the one at T = 16 ns (Part B), so part of the power increase in question 9 is not "just frequency". Estimate how much, by comparing energy per cycle (P/f) at 1 ns and at 16 ns for W = 64.

## What to hand in

A PDF report, no more than 6 pages plus an appendix:
- Your plots, **with your fitted lines**, axis labels and units. At least: area vs W (Q2, Q5), arrival vs W (Q6), power vs W (Q8) and power vs f (Q9).
- A table of every slope and intercept you fitted: value, units, the range of W or f you fitted over, and the fit quality.
- Answers to questions 1–11. Each answer should point to a plot or a number.
- Appendix: your spreadsheet formulas or plotting code (with the AI prompt, if you used one), and `results/summary.csv`.

### Grading (100)

| | Points |
|---|---|
| Sweep ran; CSV correct | 10 |
| Part A: prediction, fits, flip-flop analysis (Q1–4) | 25 |
| Part B: area cost of speed, delay/bit, W = 32 speed/area table (Q5–7) | 30 |
| Part C: power slopes, energy/bit, leakage, seq vs comb (Q8–11) | 25 |
| Report quality: units everywhere, fits drawn on plots, ranges stated | 10 |
