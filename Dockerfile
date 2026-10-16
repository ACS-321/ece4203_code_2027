# ECE4203 (Cal Poly) digital IC design image, 2027.
#
# Built by .github/workflows/image.yml through the devcontainer CLI, which layers
# the desktop-lite and sshd features on top (see .devcontainer/build/).
# Every version below is pinned and recorded in VERSIONS.md.

# OpenROAD-flow-scripts release 26Q4 (git tag 26Q4 = commit ecb3cfdeb).
# Ubuntu 22.04, OpenROAD + yosys 0.68 + KLayout 0.30.12.
ARG ORFS_IMAGE=openroad/orfs:26Q3-705-gecb3cfdeb@sha256:6da005d1c3447799f7401215174196c75ba9ec7e28417624d0c20225f85d594c
FROM ${ORFS_IMAGE}

# Links the GHCR package to this repository (permissions, README, "Packages" sidebar).
LABEL org.opencontainers.image.source="https://github.com/dvanblerkom/ece4203_code_2027" \
      org.opencontainers.image.description="Cal Poly ECE4203: ORFS + OSS CAD Suite + sky130A PDK + noVNC desktop"

ARG OSS_CAD_DATE=2026-10-16
ARG OSS_CAD_SHA256=95aead487287adf8fbbe965799e88e2ccb12a544f3d0a27b27f80bfc7c892911
ARG OPEN_PDKS_VERSION=1e3554706ddbb2529193bdabbc7128296f3cb44a

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ------------------------------------------------------------------
# Desktop session + small tools.
# TigerVNC, noVNC and dbus-x11 come from the desktop-lite feature.
# ------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y \
        xfce4 xfce4-terminal \
        ngspice \
        sudo locales curl ca-certificates zstd xauth \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# OSS CAD Suite: iverilog, verilator, gtkwave, surfer, cocotb, sby/eqy, ...
# FPGA-only tools are removed (about 1 GB).
# ------------------------------------------------------------------
COPY docker/prune-oss-cad.sh docker/install-pdk.sh /usr/local/sbin/
RUN url="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_CAD_DATE}/oss-cad-suite-linux-x64-$(echo "${OSS_CAD_DATE}" | tr -d -).tgz" \
 && curl -fsSL --retry 3 -o /tmp/oss-cad.tgz "$url" \
 && echo "${OSS_CAD_SHA256}  /tmp/oss-cad.tgz" | sha256sum -c - \
 && tar -xzf /tmp/oss-cad.tgz -C /opt \
 && rm /tmp/oss-cad.tgz \
 && prune-oss-cad.sh /opt/oss-cad-suite

# ------------------------------------------------------------------
# sky130A PDK (open_pdks): sky130_fd_sc_hd + sky130_fd_pr + tech files, ~325 MB.
# ------------------------------------------------------------------
ENV PDK_ROOT=/opt/pdk \
    PDK=sky130A
RUN install-pdk.sh "${OPEN_PDKS_VERSION}" "${PDK_ROOT}"

# ------------------------------------------------------------------
# PATH: ORFS tools first, OSS CAD Suite LAST.
# `yosys`, `openroad` and `sta` are always the ORFS builds the flow was tested
# with. OSS CAD tools that ORFS lacks (iverilog, verilator, gtkwave, ...) are
# still found. The OSS CAD yosys is available as `oss-yosys`.
# /etc/profile.d covers SSH/login shells, where PAM resets PATH.
# ------------------------------------------------------------------
ENV ORFS_HOME=/OpenROAD-flow-scripts \
    FLOW_HOME=/OpenROAD-flow-scripts/flow \
    OPENROAD=/OpenROAD-flow-scripts/tools/OpenROAD
ENV PATH=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin:/OpenROAD-flow-scripts/tools/install/yosys/bin:/OpenROAD-flow-scripts/tools/install/kepler-formal/bin:${PATH}:/opt/oss-cad-suite/bin
RUN printf '%s\n' \
        'case ":$PATH:" in *:/OpenROAD-flow-scripts/tools/install/OpenROAD/bin:*) ;; *)' \
        '  export PATH="/OpenROAD-flow-scripts/tools/install/OpenROAD/bin:/OpenROAD-flow-scripts/tools/install/yosys/bin:/OpenROAD-flow-scripts/tools/install/kepler-formal/bin:$PATH:/opt/oss-cad-suite/bin" ;;' \
        'esac' \
        'export PDK_ROOT=/opt/pdk PDK=sky130A FLOW_HOME=/OpenROAD-flow-scripts/flow' \
        > /etc/profile.d/ece4203.sh \
 && printf '#!/bin/sh\nexec /opt/oss-cad-suite/bin/yosys "$@"\n' > /usr/local/bin/oss-yosys \
 && chmod 755 /usr/local/bin/oss-yosys

# ------------------------------------------------------------------
# Student account: uid 1000, passwordless sudo, no login password.
# ------------------------------------------------------------------
RUN (id -u user >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash user) \
 && echo 'user ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user \
 && chmod 0440 /etc/sudoers.d/user

CMD ["/bin/bash"]
