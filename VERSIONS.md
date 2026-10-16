# Pinned versions

Every external component is pinned to an exact version. "Checked" is the date
the version was looked up as the latest stable one.

## Phase 1: desktop (`.devcontainer/devcontainer.json`)

| Component | Pin | Checked | Source / notes |
|---|---|---|---|
| Base image (unchanged in Phase 1) | `dvanblerkom/ece4203:2026` | — | Pulled only, never modified. Replaced in Phase 2 |
| desktop-lite feature | `ghcr.io/devcontainers/features/desktop-lite:1.2.10` | 2026-10-16 | Latest tag on GHCR. TigerVNC + fluxbox packages from the distro |
| noVNC (via feature option) | `1.6.0` | 2026-10-16 | Feature default and tested by its maintainers. Upstream latest is v1.7.0 |
| websockify (hardcoded in feature) | `0.10.0` | 2026-10-16 | Set inside desktop-lite 1.2.10 and not configurable. Upstream latest is v0.13.0 |
| common-utils feature | `ghcr.io/devcontainers/features/common-utils:2.7.1` | 2026-10-16 | Used only for passwordless sudo for `user` (zsh/oh-my-zsh/upgrade disabled) |
| sshd feature | `ghcr.io/devcontainers/features/sshd:1.1.0` | 2026-10-16 | For `gh codespace ssh` (X11 fallback) |

## Planned for Phase 2 (not used yet)

| Component | Pin | Checked | Notes |
|---|---|---|---|
| ORFS image | `openroad/orfs:26Q3-705-gecb3cfdeb` @ `sha256:6da005d1c3447799f7401215174196c75ba9ec7e28417624d0c20225f85d594c` | 2026-10-16 | Same commit as the ORFS git tag **26Q4** (`ecb3cfdeb`). Ubuntu 22.04, yosys v0.68, KLayout 0.30.12 |
| OSS CAD Suite | `2026-10-16` | 2026-10-16 | `oss-cad-suite-linux-x64-20261016.tgz` (748 MB) |
