# Example designs on two technologies

The same RTL run through OpenROAD-flow-scripts on two very different processes, so
you can see what a ~20× smaller node does to area, speed, power and wiring.

```bash
cd openroad_flow
make DESIGN=gcd both          # one design on both platforms
make ladder                   # every design below on both platforms, then metrics
make metrics                  # metrics/metrics.csv, metrics.md, compare.png, scaling.png
make DESIGN=gcd PLATFORM=asap7 gui_final    # look at a finished layout
```

## The two platforms

| | **sky130hd** | **asap7** |
|---|---|---|
| Node | 130 nm, planar bulk CMOS | 7 nm, FinFET (predictive) |
| Source | SkyWater / Google open PDK; really manufacturable (Tiny Tapeout, chipIgnite, …) | ASU + Arm academic PDK; **not manufacturable**, modeled on a 7 nm process |
| Std-cell library | `sky130_fd_sc_hd` (high density, 2.72 µm rows) | `asap7sc7p5t` (7.5-track, 0.27 µm rows) |
| Supply | 1.8 V | 0.7 V |
| Metal layers used | 5 (li1 + met1–met5) | 9 (M1–M9) |
| **Time unit in SDC/reports** | **ns** | **ps** |
| Used elsewhere in the course | Lab 1 (Yosys + OpenSTA), KLayout cells, ngspice models | Phase 4 macro example (fakeram7) |

**Why these two?** They're the widest node gap among the well-supported ORFS platforms.
Both have the same example designs in ORFS, and both run in a Codespace in minutes (the default is the 2-core machine; see the note on runtimes below).
- **nangate45** (45 nm) would make a reasonable third point between them, but its open cell library is old and coarse.
- **ihp-sg13g2** is the same node as sky130 (130 nm), so it shows no scaling. It's used for the pad-ring example instead.
- **gf180** (180 nm) is too close to sky130 to show much.

`scripts/orfs_metrics.py` converts asap7's ps to ns, so every table and plot uses one set of units: ns, MHz, µm², mW, µm and seconds.

## The ladder

| # | Design | What it is | Cells (sky130hd) | Where | Notes |
|---|---|---|---|---|---|
| 1 | `registered_adder` | 64-bit adder between input and output registers (Lab 1's design) | ~800 | `openroad_flow/designs/{sky130hd,asap7}/registered_adder` | The critical path is one carry chain, which is easy to find in the timing report. sky130hd keeps the Lab 1 pin layout; asap7 uses automatic pin placement |
| 2 | `gcd` | Euclid's GCD, 16-bit | ~300 | ORFS (`$FLOW_HOME/designs`) | ORFS's smoke-test design. A good first `gui_final` |
| 3 | `riscvsingle` | **Single-cycle RV32I subset**: Harris & Harris *DDCA*, from [CORE-V-Wally](https://github.com/openhwgroup/cvw) `examples/verilog/riscvsingle` (MIT) | ~3,700 | `openroad_flow/designs/{src,sky130hd,asap7}/riscvsingle` | Core only; the instruction and data memories are outside the block. The 31×32 register file (992 flops) dominates the area. RTL test: `make -C openroad_flow/designs/src/riscvsingle/tb sim` |
| 4 | `aes` | AES-128 cipher core | ~15–20k | ORFS | Medium. Routing congestion starts to show |
| 5 | `ibex` *(optional)* | lowRISC Ibex, 2-stage RV32IMC | ~20–30k | ORFS | A real production core. `make ladder LADDER="registered_adder gcd riscvsingle aes ibex"` |

### Expected runtime (4 vCPU)

Measured by `.github/workflows/ladder.yml` on GitHub's 4-vCPU / 16 GB runners, which are comparable to a **4-core** Codespace. The default Codespace is **2-core / 8 GB** to keep core-hours down, so expect the longer runs (riscvsingle and aes on sky130hd) to take noticeably longer there. Peak memory in these runs was at most 2.8 GB, so 8 GB is enough. For a 4-core machine, pick it on the Codespace creation screen (Machine type). Times are the sum of all ORFS stage times (`runtime_s` in `metrics.csv`); add about 1 minute of make and setup overhead.

| Design | sky130hd | asap7 |
|---|---|---|
| registered_adder | 2.3 min | 1.4 min |
| gcd | 1.6 min | 0.9 min |
| riscvsingle | 20 min | 6.8 min |
| aes | 37 min | 12 min |
| ibex | not run by default | not run by default |

sky130hd takes about 3× longer than asap7 for the same RTL, mostly in detailed routing. Its cells and wires are much larger relative to the routing grid, and the router does more work per net. For a 50-minute lab, give students gcd and riscvsingle on both platforms, and run aes ahead of time or as homework.

### Measured results (ORFS 26Q4, `:2027-dev` image)

| Design | Platform | Cells | Cell area (µm²) | Utilization | Clock (ns) | Worst slack (ns) | Fmax (MHz) | Power (mW) | Wirelength (µm) |
|---|---|---|---|---|---|---|---|---|---|
| registered_adder | sky130hd | 1,807 | 15,630 | 0.44 | 2.0 | −1.59 | 278 | 11.9 | 36,150 |
| registered_adder | asap7 | 1,667 | 182 | 0.14 | 0.40 | +0.015 | 2,595 | 2.03 | 4,047 |
| gcd | sky130hd | 548 | 5,413 | 0.92 | 1.1 | −1.46 | 391 | 9.85 | 11,730 |
| gcd | asap7 | 427 | 45 | 0.74 | 0.31 | −0.041 | 3,038 | 1.37 | 772 |
| riscvsingle | sky130hd | 5,146 | 61,420 | 0.54 | 10 | +0.27 | 149 | 10.9 | 184,700 |
| riscvsingle | asap7 | 8,083 | 946 | 0.56 | 1.0 | +0.023 | 1,469 | 5.70 | 30,870 |
| aes | sky130hd | 18,439 | 130,500 | 0.59 | 3.6 | −0.054 | 274 | 570 | 574,200 |
| aes | asap7 | 12,826 | 1,452 | 0.74 | 0.38 | −0.011 | 2,559 | 83.4 | 49,880 |

registered_adder (64-bit) misses its 2.0 ns target on sky130hd by 1.6 ns. A 64-bit carry chain doesn't fit there, which matches the Lab 1 sweep. On asap7 the same RTL makes 400 ps. Comparing the two critical paths in `gui_final` is a good exercise.

The gcd and aes clock targets come from ORFS's own configs, which are set near each platform's limit, so small negative slack is expected. gcd on sky130hd misses by more (−1.46 ns at 1.1 ns). That's a good discussion point: compare its reported Fmax with asap7's.

For the same RTL, sky130hd needs **~65–120× the cell area** and **~6–15× the wirelength**, and runs **~8–10× slower** (Fmax). Power is **~2–7× higher** even though sky130hd runs at a far lower clock; compare energy per cycle (P/f) in question 4. Question 1 below asks why that area ratio is far below (130/7)².

## What `make metrics` reports

| Column | Meaning | From ORFS |
|---|---|---|
| `cell_area_um2` | standard-cell area after the full flow (includes buffers, fill excluded) | `finish__design__instance__area__stdcell` |
| `utilization` | cell area / core area | `finish__design__instance__utilization__stdcell` |
| `clock_period_ns` | target from the SDC | `results/…/6_final.sdc` |
| `setup_ws_ns` | worst setup slack (negative = fails timing) | `finish__timing__setup__ws` |
| `fmax_mhz` | 1 / (period − slack) | `finish__timing__fmax…` if ORFS reports it, else computed |
| `power_mw` | total power (internal + switching + leakage) at the target clock | `finish__power__total` |
| `wirelength_um` | detailed-routed wirelength | `detailedroute__route__wirelength` |
| `runtime_s`, `peak_mem_mb` | sum of stage times, worst stage memory | `Elapsed time` lines in `logs/` |

`compare.png` has one panel per metric (log scale where values span decades), with bars per platform. `scaling.png` shows sky130hd / asap7 per design, so 20× means sky130hd is 20 times larger.

## Questions for students

1. From `scaling.png`: the cell-area ratio is much smaller than (130/7)² ≈ 345. Why? Think about what doesn't shrink with the drawn gate length: track pitch, fin quantization, and the cell height in tracks.
2. Same design, same flow: why is the Fmax ratio much smaller than the area ratio? Which parts of the critical-path delay are set by wires rather than transistors? Use `make DESIGN=riscvsingle PLATFORM=asap7 gui_final` → Timing Report to look at one path.
3. riscvsingle: what fraction of the cell area is the register file? Look at `reports/…/synth_stat.txt` and count the `edfxtp` flops. What would an SRAM macro save? That's the Phase 4 macro example.
4. Power is reported at each design's own target clock. Normalize it to energy per cycle (P / f). Which technology wins, and by how much?
