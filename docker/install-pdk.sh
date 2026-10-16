#!/bin/bash
# Install a pruned sky130A PDK (open_pdks build, as published by ciel) into $PDK_ROOT.
#
# Uses the same release tarballs `ciel enable` downloads, fetched directly so that
# every file is pinned by SHA256. Installs:
#   common           tech files: ngspice/klayout/magic/netgen/xschem setup
#   sky130_fd_sc_hd  high-density standard cells (lib/lef/gds/verilog/spice/cdl)
#   sky130_fd_pr     primitive devices + ngspice transistor models
# Then removes the sky130B variant and the two 70 MB ccsnoise liberty files.
#
# Usage: install-pdk.sh <open_pdks commit> <PDK_ROOT>
set -euo pipefail
version="${1:?usage: $0 <open_pdks commit> <PDK_ROOT>}"
root="${2:?usage: $0 <open_pdks commit> <PDK_ROOT>}"
base="https://github.com/fossi-foundation/ciel-releases/releases/download/sky130-${version}"

# name sha256 (for open_pdks 1e3554706ddbb2529193bdabbc7128296f3cb44a)
assets=(
    "common          47469820255746bd16305678bed1318390b3ae1c4684783d3f6e3369498f6655"
    "sky130_fd_sc_hd 02c00c143d1d3e36dd9f722f319773508bafe3cf2509d6d585bf81e8a46cb779"
    "sky130_fd_pr    fa19ed11730c439ff4d410448274733125a40c393ddee59f6f33e1f200bd1bf6"
)

mkdir -p "$root"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for entry in "${assets[@]}"; do
    read -r name sha <<<"$entry"
    echo "install-pdk: ${name}"
    curl -fsSL --retry 3 -o "${tmp}/${name}.tar.zst" "${base}/${name}.tar.zst"
    echo "${sha}  ${tmp}/${name}.tar.zst" | sha256sum -c --quiet -
    tar --zstd -xf "${tmp}/${name}.tar.zst" -C "$root"
    rm -f "${tmp}/${name}.tar.zst"
done

rm -rf "${root}/sky130B"
rm -f "${root}"/sky130A/libs.ref/sky130_fd_sc_hd/lib/*_ccsnoise.lib
echo "${version}" > "${root}/sky130A/OPEN_PDKS_VERSION"

# Sanity checks for what the labs use.
for f in libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
         libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
         libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
         libs.tech/ngspice/sky130.lib.spice \
         libs.tech/klayout/tech/sky130A.lyt; do
    test -s "${root}/sky130A/${f}" || { echo "install-pdk: missing ${f}" >&2; exit 1; }
done
du -sh "${root}/sky130A"
