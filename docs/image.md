# The ECE4203 image

`ghcr.io/dvanblerkom/ece4203` = ORFS 26Q4 + OSS CAD Suite (no FPGA tools) +
sky130A PDK + XFCE/noVNC desktop. Exact versions are in [../VERSIONS.md](../VERSIONS.md).

## What's where

| | Path | Notes |
|---|---|---|
| ORFS flow | `/OpenROAD-flow-scripts/flow` (`$FLOW_HOME`) | Run it through `openroad_flow/Makefile` in this repo |
| OpenROAD, OpenSTA, Yosys (ORFS builds) | `/OpenROAD-flow-scripts/tools/install/{OpenROAD,yosys}/bin` | First on PATH |
| OSS CAD Suite | `/opt/oss-cad-suite/bin` | **Last** on PATH |
| sky130A PDK | `/opt/pdk/sky130A` (`$PDK_ROOT/$PDK`) | `libs.ref/sky130_fd_sc_hd/{lib,lef,gds,verilog,spice,cdl}`, `libs.ref/sky130_fd_pr`, `libs.tech/{ngspice,klayout,magic,netgen,xschem}` |
| Desktop | desktop-lite feature | See [desktop.md](desktop.md) |

### Which `yosys` runs, and why

`PATH` is `ORFS bins : system : /opt/oss-cad-suite/bin`, so:

- `yosys` is **ORFS's Yosys 0.68**, the version ORFS 26Q4 was tested with. `openroad` and `sta` likewise come from ORFS. The ORFS flow also calls `$YOSYS_EXE`/`$OPENROAD_EXE` explicitly, so the flow never picks up the wrong one regardless.
- `iverilog`, `vvp`, `verilator`, `gtkwave`, `surfer`, `ghdl`, `sby`, `eqy`, `cocotb-config` and the formal solvers exist only in OSS CAD Suite, so PATH order doesn't matter for them.
- OSS CAD Suite's development Yosys (0.70+145) is available as **`oss-yosys`**.
  - Lab 1 showed why this matters. Mapping the registered adder with `oss-yosys` produced a netlist with a corrupted pin name (`.\$auto$ff.cc:337:slice$123` on an `a21boi_0` cell), which iverilog rejects. Yosys 0.68 produces a clean netlist that passes the gate-level testbench.
- OSS CAD Suite's `environment` script is deliberately **not** sourced. It would prepend OSS CAD to PATH, including its own python3. Its tools are wrapper scripts that find their own libraries, so plain PATH use works.
- `/etc/profile.d/ece4203.sh` sets the same PATH for login and SSH shells, where PAM resets PATH.

### What was removed from OSS CAD Suite (`docker/prune-oss-cad.sh`)

All FPGA-only tools: nextpnr (all architectures) and its chip databases, icestorm, prjtrellis, prjoxide, apicula (Gowin), openFPGALoader, openocd, dfu-util, fujprog and ecpprog. This takes the suite from 2505 MB to 1515 MB. To restore one, remove its line from the script and rebuild.

### PDK

The PDK comes from the same open_pdks release tarballs `ciel` uses, downloaded directly and SHA256-checked (`docker/install-pdk.sh`). It was removed from the git repository, including its history, so clones and forks are about 2 MB instead of 65 MB.

- ngspice simulations need the transistor models:
  `.lib /opt/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice tt`.
  The sky130 devices are **subcircuits**, so instance names must start with `X` (`XM1 …`), not `M`. The `klayout/*.spice` files are LVS netlists and use `M`.
- Lab 1 builds a copy of `sky130_fd_sc_hd.v` with one `specify` block commented out. This is the same fix that used to be committed in `pdk/`; the PDK itself isn't modified.

## Building and publishing

`.github/workflows/image.yml` uses [devcontainers/ci](https://github.com/devcontainers/ci) to:
1. build `Dockerfile`,
2. add the features from `.devcontainer/build/devcontainer.json`,
3. start the container and run `docker/smoke-test.sh` inside it,
4. push to GHCR, only if the smoke test passed.

The features' entrypoints, `containerEnv` and `remoteUser` are stored in the image's `devcontainer.metadata` label, so `.devcontainer/devcontainer.json` only needs the image name.

| Trigger | Result |
|---|---|
| Pull request touching the image | build + smoke test, **no push** |
| `git tag v2027.0.0-dev1 && git push origin v2027.0.0-dev1` | pushes `:v2027.0.0-dev1` and `:2027-dev` |
| `git tag v2027.1.0 && git push origin v2027.1.0` | pushes `:v2027.1.0` and `:2027` |
| Actions → image → Run workflow (push ✓) | pushes `:2027-dev` and `:sha-…` (only works once the workflow is on `main`) |

A tag-triggered run uses the workflow file *at the tagged commit*. So you can tag a PR branch to publish a `-dev` image and test it in a Codespace before merging.

**Runner disk:** the ORFS base is about 6 GB unpacked and the final image about 9 GB. The workflow deletes preinstalled SDKs (.NET, Android, GHC, …) and moves Docker's storage to `/mnt` when that disk has more than 40 GB free.

### Making the image pullable by student Codespaces

The first push creates a **private** package. Make it public once:

1. github.com/dvanblerkom, then **Packages**, then **ece4203**, then **Package settings**.
2. **Danger Zone**, then **Change visibility**, then **Public**.
3. Under **Manage Actions access**, check that `dvanblerkom/ece4203_code_2027` has **Write** access. A package first pushed from that repo's workflow is linked to it automatically.

A public image can be pulled without credentials by Codespaces created from this repo, by forks, and by any computer running Docker.

### Codespaces prebuilds (optional)

The image already contains everything, so a new Codespace only has to pull it (a few minutes the first time on a host). Prebuilds also cache that pull:

1. Repo **Settings**, then **Codespaces**, then **Set up prebuild**.
2. Branch `main`, configuration `.devcontainer/devcontainer.json`.
3. Region(s) near Cal Poly (US West), trigger "On configuration change".
4. Prebuilds use Actions minutes and storage on your account. Watch usage at the start of the term.

### Testing locally (with Docker)

```bash
npm install -g @devcontainers/cli
devcontainer build --workspace-folder . --config .devcontainer/build/devcontainer.json --image-name ece4203:local
devcontainer up    --workspace-folder . --config .devcontainer/build/devcontainer.json
devcontainer exec  --workspace-folder . --config .devcontainer/build/devcontainer.json bash docker/smoke-test.sh
```
