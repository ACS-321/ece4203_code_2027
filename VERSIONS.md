# Pinned versions

Every external component is pinned to an exact version. "Checked" is the date the
version was looked up as the latest stable one. To update a version, change it here
and in the file listed under "Where".

## Image (`Dockerfile`, built by `.github/workflows/image.yml`)

| Component | Pin | Checked | Where | Notes |
|---|---|---|---|---|
| ORFS base image | `openroad/orfs:26Q3-705-gecb3cfdeb` @ `sha256:6da005d1c3447799f7401215174196c75ba9ec7e28417624d0c20225f85d594c` | 2026-10-16 | `Dockerfile` `ORFS_IMAGE` | Commit `ecb3cfdeb` is the ORFS git tag **26Q4** (quarterly release). There's no plain `26Q4` tag on Docker Hub. The 2026 image was `v3.0-4512-g528ad3d8a`, which is the **26Q1** tag |
| ↳ OpenROAD / OpenSTA | as shipped in 26Q4 | — | — | `openroad`, `sta` in `/OpenROAD-flow-scripts/tools/install/OpenROAD/bin` |
| ↳ Yosys | 0.68 | — | — | ORFS build; it's the `yosys` on PATH |
| ↳ KLayout | 0.30.12 | 2026-10-16 | — | Installed by ORFS; also the latest upstream release, so no separate install |
| ↳ Ubuntu | 22.04 | — | — | |
| OSS CAD Suite | `2026-10-16`, sha256 `95aead487287adf8fbbe965799e88e2ccb12a544f3d0a27b27f80bfc7c892911` | 2026-10-16 | `Dockerfile` `OSS_CAD_DATE`, `OSS_CAD_SHA256` | 2505 MB → 1515 MB after `docker/prune-oss-cad.sh` removes the FPGA tools. Includes iverilog 14.0 (devel), Verilator 5.053 (devel), GHDL 7.0-dev, cocotb 2.1.0.dev, Yosys 0.70+145 (as `oss-yosys`), z3 4.15.5, Yices 2.7.0, Bitwuzla 0.9.1 |
| sky130 PDK (open_pdks) | `1e3554706ddbb2529193bdabbc7128296f3cb44a` (2026-10-01) | 2026-10-16 | `Dockerfile` `OPEN_PDKS_VERSION`, SHA256s in `docker/install-pdk.sh` | ciel release `sky130-<hash>`: `common`, `sky130_fd_sc_hd`, `sky130_fd_pr`. sky130A only; ccsnoise libs removed. 325 MB at `/opt/pdk/sky130A` |
| ngspice | Ubuntu 22.04 package (36) | — | `Dockerfile` apt | Not in OSS CAD Suite |
| XFCE | Ubuntu 22.04 packages | — | `Dockerfile` apt | |

## Devcontainer features (baked into the image by `.devcontainer/build/devcontainer.json`)

| Component | Pin | Checked | Notes |
|---|---|---|---|
| desktop-lite | `ghcr.io/devcontainers/features/desktop-lite:1.2.10` | 2026-10-16 | TigerVNC + fluxbox from Ubuntu packages |
| ↳ noVNC | `1.6.0` (feature option) | 2026-10-16 | The feature's default. Upstream latest is v1.7.0 |
| ↳ websockify | `0.10.0` | 2026-10-16 | Set inside desktop-lite 1.2.10 and not configurable. Upstream latest is v0.13.0 |
| sshd | `ghcr.io/devcontainers/features/sshd:1.1.0` | 2026-10-16 | For `gh codespace ssh` |

## CI (`.github/workflows/image.yml`, actions pinned by commit SHA)

| Action | Version | SHA |
|---|---|---|
| actions/checkout | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| docker/login-action | v4.6.0 | `dbcb813823bdd20940b903addbd779551569679f` |
| devcontainers/ci | v0.3.1900000450 | `513af61f4de4f75d37e4438f184ba4358f0fc1ca` |
| Runner | `ubuntu-24.04` | |

## Published image

| Tag | Meaning |
|---|---|
| `ghcr.io/dvanblerkom/ece4203:2027-dev` | Latest `v*-dev*` tag build; what `.devcontainer/devcontainer.json` uses during development |
| `ghcr.io/dvanblerkom/ece4203:2027` | Latest release tag (`v2027.x.y`) |
| `ghcr.io/dvanblerkom/ece4203:<git tag>` | Immutable per-release tag |
