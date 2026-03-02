FROM openroad/orfs:v3.0-4512-g528ad3d8a

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal tigervnc-standalone-server novnc ngspice sudo \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------------
# Add OSS CAD Suite
# ------------------------------------------------------------------
# Copy the tarball you downloaded from:
# https://github.com/YosysHQ/oss-cad-suite-build/releases
COPY oss-cad-suite-linux-x64-*.tgz /tmp/oss-cad.tgz

RUN tar -xzf /tmp/oss-cad.tgz -C /opt/ \
 && rm /tmp/oss-cad.tgz

# Make OSS CAD tools available on PATH for all shells
#ENV PATH="${PATH}:/opt/oss-cad-suite/bin"

RUN useradd -m -u 1000 -s /bin/bash user && \
    echo "user:ece4203" | chpasswd && \
    usermod -aG sudo user

# Set up VNC password and xstartup for user
RUN mkdir -p /home/user/.vnc && \
    echo "ece4203" | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

# noVNC redirect so /index.html goes straight to vnc.html
RUN echo '<meta http-equiv="refresh" content="0; url=/vnc.html">' \
    > /usr/share/novnc/index.html

USER user
WORKDIR /home/user/ece4203

RUN mkdir /home/user/ece4203/flow
RUN ln -s /OpenROAD-flow-scripts/flow/platforms /home/user/ece4203/flow/
RUN ln -s /OpenROAD-flow-scripts/flow/designs /home/user/ece4203/flow/
RUN ln -s /OpenROAD-flow-scripts/flow/scripts /home/user/ece4203/flow/
RUN ln -s /OpenROAD-flow-scripts/flow/test /home/user/ece4203/flow/
RUN ln -s /OpenROAD-flow-scripts/flow/tutorials /home/user/ece4203/flow/
RUN ln -s /OpenROAD-flow-scripts/flow/util /home/user/ece4203/flow/
RUN cp /OpenROAD-flow-scripts/flow/Makefile  /home/user/ece4203/flow/

# Default to bash so students get an interactive shell
CMD ["/bin/bash"]
