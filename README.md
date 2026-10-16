# ece4203_code (2027)

Cal Poly ECE4203 digital IC design environment: OpenROAD-flow-scripts, Yosys,
OpenSTA, KLayout, ngspice and OSS CAD Suite in a GitHub Codespace.

- **Desktop for GUI tools (KLayout, `openroad -gui`):** open the **Ports** tab and
  click port **6080 "Desktop (noVNC)"**. The password is `ece4203`. For
  troubleshooting and fallbacks, see [docs/desktop.md](docs/desktop.md).
- **Physical design:** `cd openroad_flow && make DESIGN=gcd` (any ORFS design, or your own
  under `openroad_flow/designs/`). Run `make list` to see what's available.
- **Two technologies, design ladder, metrics:** [docs/examples.md](docs/examples.md).
- **SRAM macros, hardened blocks, pad ring:** [docs/macros-pads.md](docs/macros-pads.md).
- **Lab 1:** `cd lab1 && make sim synth sta summary`.
- **Image contents** (ORFS 26Q4, OSS CAD Suite, sky130A PDK at `/opt/pdk`, and which `yosys`
  runs): [docs/image.md](docs/image.md). Tool versions: [VERSIONS.md](VERSIONS.md).
