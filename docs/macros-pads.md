# Macros, hardened blocks and a pad ring

Three examples that go beyond flat standard-cell blocks. All run from `openroad_flow/`
with the same wrapper as the other designs. Open the result with
`make DESIGN=<d> PLATFORM=<p> gui_final` in the desktop.

| Example | Command | Runtime (4 vCPU) |
|---|---|---|
| SRAM macros, automatic placement | `make DESIGN=riscv32i PLATFORM=asap7` | 15 min |
| SRAM macros, hand placement | `make DESIGN=riscv32i_macros PLATFORM=asap7` | 30 min |
| Hardened block (register file) | `make DESIGN=riscvsingle_hier PLATFORM=asap7` | 5 min (block 3.4 + top 1.5) |
| Flat version, for comparison | `make DESIGN=riscvsingle PLATFORM=asap7` | 4–7 min |
| Pad ring | `make DESIGN=padring_counter PLATFORM=ihp-sg13g2` | 20 s |

Runtimes are ORFS stage time on GitHub's 4-vCPU runners, measured by `.github/workflows/macros-pads.yml` (Actions → macros-pads).

### Measured results (ORFS 26Q4, `:2027-dev` image)

| Design | Cells | Cell area (µm²) | Die (µm²) | Utilization | Worst slack (ns) | Fmax (MHz) | Power (mW) | Wirelength (µm) |
|---|---|---|---|---|---|---|---|---|
| riscv32i (RTLMP) | 10,350 | 1,244 | 5,350 | 0.49 | −0.020 | 1,103 | 31.4 | 52,960 |
| riscv32i_macros (hand) | 13,465 | 1,450 | 12,100 | 0.17 | −0.099 | 1,009 | 16.3 | 92,970 |
| riscvsingle (flat) | 8,083 | 946 | 2,040 | 0.56 | +0.023 | 1,469 | 5.70 | 30,870 |
| riscvsingle_hier (top) | 2,312 | 175 | 5,843 | 0.05 | −0.011 | 1,605 | 0.45 | 13,220 |
| ↳ regfile block | 7,011 | 824 | 1,982 | 0.51 | +0.083 | 1,091 | 5.00 | 24,850 |
| padring_counter (IHP) | 42 | 884 | 1,104,000 | 0.007 | +1.97 | 742 | 1.17 | 4,325 |

What the numbers show:
- **Hand placement lost to RTLMP here.** The fixed 110 × 110 µm die (`riscv32i_macros/config.mk`) is 2.3× larger than the one ORFS sizes automatically. The longer wires need more buffers (+30% cells) and cost timing. Shrinking `DIE_AREA`/`CORE_AREA` and moving the macros in `macros.tcl` is a good exercise.
- **Hardening the register file** keeps total cell area about the same (175 + 824 µm² vs 946 µm² flat), but the top level misses timing slightly (−11 ps vs +23 ps flat). The block's fixed 30%/30% I/O budget and its fixed pins limit what the top level can optimize. The top's utilization is low because the macro's area isn't counted as standard cells.
- **The pad ring** is 42 cells in a 1.05 mm² die (0.7% utilization). It's entirely pad limited.

---

## 1. SRAM macros (`riscv32i`, `riscv32i_macros` on asap7)

ORFS's `riscv32i` is a single-cycle RV32I core (OSU, ECEN 4243). Its data memory
is four **fakeram7_256x32** SRAM macros (256 words × 32 bits, 8.36 × 42 µm each).
A *fake RAM* has a real-looking abstract: a LEF with the outline, pins and routing
blockages, and a liberty file with access time, setup/hold and power. It has no
transistors inside. That's all place and route needs.

| Variable | What it does here |
|---|---|
| `ADDITIONAL_LEFS` / `ADDITIONAL_LIBS` | add the macro's abstract and timing model |
| `MACRO_PLACEMENT_TCL` | `riscv32i_macros/macros.tcl`: finds the four macro instances in the database, then `place_macro -macro_name <inst> -location {x y} -orientation MY` |
| `MACRO_PLACE_HALO` | keep-out ring (µm) around each macro where no standard cells go |
| (none) | without a placement file, ORFS's RTL macro placer (RTLMP) chooses positions; that's ORFS's `riscv32i` |
| PDN | the asap7 platform PDN adds a macro grid that connects the SRAMs' power pins to the core grid |

**In the GUI**
- Turn off everything but **Instances → Blocks** to see just the four SRAMs. Then turn on **Blockages → Placement** to see the halos.
- **Floorplan** view (`make … gui_floorplan`): where RTLMP put the macros versus `macros.tcl`.
- **Power** nets: the straps over the macros and the vias down to the macro pins.
- **Timing report:** the worst path, and whether it goes through an SRAM (`rd_out`) or ends at one (`addr_in`).

**Questions**
1. The macros' pins are all on their left edge (look at the LEF, or zoom in). Why does `macros.tcl` mirror them (`MY`)? Change two of them to `R0` and compare wirelength and worst slack.
2. Compare `riscv32i` (RTLMP) with `riscv32i_macros` (hand placed): cell area, wirelength and worst slack in `make metrics`. Which is better, and why?
3. Set `MACRO_PLACE_HALO = 0 0` and rerun. What changes in placement density next to the macros, and in routing congestion (**Heat Maps → Routing congestion**)?

## 2. Hardened block (`riscvsingle_hier` on asap7)

Same RTL as `riscvsingle`, but the 31×32 **register file is hardened first** and
then used as a macro in the core. This is ORFS's `BLOCKS` flow.

```
designs/asap7/riscvsingle_hier/config.mk           BLOCKS = regfile, SYNTH_HIERARCHICAL = 1
designs/asap7/riscvsingle_hier/regfile/config.mk   the block's own flow: M1-M5 only, block PDN
```

1. `make` sees `BLOCKS = regfile` and first runs the whole flow on `regfile/config.mk`, then `generate_abstract`.
2. That writes `results/asap7/riscvsingle_hier_regfile/base/regfile.lef`, `regfile_typ.lib` and `6_final.gds`.
3. The top level reads those as if `regfile` were an SRAM: it's placed as a macro, timed through its liberty model, and merged into the final GDS.

**In the GUI**
- Open the block by itself: `make DESIGN=riscvsingle_hier PLATFORM=asap7 DESIGN_CONFIG=$PWD/designs/asap7/riscvsingle_hier/regfile/config.mk gui_final`.
- In the top level, the block is one instance. Look at its pins on the block edge and the top-level routing on M6 and above passing over it.
- Compare with flat `riscvsingle` on asap7, where the register-file flops are mixed in with everything else.

**Questions**
1. Compare cell area, wirelength, worst slack and runtime for `riscvsingle` (flat) versus `riscvsingle_hier`. Hardening usually costs some area and timing. Where does each loss come from?
2. The block's SDC budgets 30% of the cycle on each side of its combinational read path. Look at `regfile_typ.lib`: what delay does it give for `A1 → RD1`? What happens to the top level if you change the budget to 10%?
3. Why does the block stop at M5 (`MAX_ROUTING_LAYER`)? What would go wrong in the top level if it used M6–M9?

## 3. Pad ring (`padring_counter` on IHP SG13G2)

An 8-bit up/down counter with **16 I/O pads**: 4 inputs, 8 outputs, and core and
I/O power pads. It's adapted from ORFS `ihp-sg13g2/i2c-gpio-expander`. IHP's
open 130 nm PDK has a real I/O library (`sg13g2_io`), and its platform script
`pad.tcl` builds the ring with OpenROAD's pad commands (ICeWall):

| Command | What it does |
|---|---|
| `make_fake_io_site`, `make_io_sites` | create the I/O rows around the die edge |
| `place_pads -row IO_NORTH …` | place the pad cells in the order given by `IO_NORTH/EAST/SOUTH/WEST_PINS` |
| `place_corners sg13g2_Corner` | corner cells that continue the ring's supply rails |
| `place_io_fill` | filler cells in the gaps, so the rails are continuous |
| `connect_by_abutment` | connects the ring's supply rails through the abutting pads |
| `place_bondpad -bond bondpad_70x70` | a 70 × 70 µm bond pad on each signal and supply pad |
| `pdn.tcl`: `add_pdn_ring … -connect_to_pads` | core power ring, connected to the `vdd`/`vss` pads |

Files: `designs/src/padring_counter/padring_counter.v` (pad cells and core),
`designs/ihp-sg13g2/padring_counter/{config.mk,pdn.tcl,constraint.sdc}`.
RTL test through the pad models:
```bash
cd openroad_flow/designs/src/padring_counter
iverilog -g2012 -o tb tb_padring_counter.v padring_counter.v $FLOW_HOME/platforms/ihp-sg13g2/verilog/sg13g2_io.v && vvp tb
```

**In the GUI**
- The whole die: pads, corners, fillers, bond pads, the seal ring at the edge, and the core power ring.
- Zoom into one output pad (`sg13g2_IOPad_q0`): `c2p` from the core, the pad's driver, and the bond pad on top.
- Follow `VDD` from the `sg13g2_IOPadVdd_inst` cell to the core ring and the Metal1 rails.

**Questions**
1. The core logic is a few hundred µm², but the die is 1.05 mm on a side. What sets the die size? This is called "pad limited". How many pads per side could the same die hold?
2. The clock is created on `sg13g2_IOPad_clk/p2c`, not on the port `clk_PAD`. Why? What delay does the input pad add, and where would you find it?
3. Why are there separate core (`vdd/vss`) and I/O (`iovdd/iovss`) supply pads? What would you change for a design drawing 100 mA?

---

### Not included: real sky130 SRAM macros
ORFS ships OpenRAM-generated sky130 SRAMs in `platforms/sky130ram/`
(`sky130_sram_1rw1r_{64x256_8,128x256_8,44x64_8,80x64_8}`), but no ORFS 26Q4 design uses them.
The same `ADDITIONAL_LEFS/LIBS/GDS` + `MACRO_PLACEMENT_TCL` recipe applies. Note that these macros are about 0.2–0.4 mm² each,
much larger than the 7 nm fake RAMs.
