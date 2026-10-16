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
Both have the same example designs in ORFS, and both run in a 4-core Codespace in minutes.
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

Measured by `.github/workflows/ladder.yml` on GitHub's 4-vCPU / 16 GB runners, which are comparable to a 4-core Codespace. Total `make all` time per design:

| Design | sky130hd | asap7 |
|---|---|---|
| registered_adder | *TBD* | *TBD* |
| gcd | *TBD* | *TBD* |
| riscvsingle | *TBD* | *TBD* |
| aes | *TBD* | *TBD* |
| ibex | *TBD* | *TBD* |

Re-run with Actions → **ladder** → Run workflow. The `ladder-metrics` artifact contains the CSV and plots. `runtime_s` in `metrics.csv` is the sum of every stage's elapsed time.

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
