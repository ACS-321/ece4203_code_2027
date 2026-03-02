#!/bin/bash

# Kill any stale instances
vncserver -kill :1 2>/dev/null || true
pkill -f novnc 2>/dev/null || true
pkill -f websockify 2>/dev/null || true

# Clean up lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Start vncserver
vncserver :1 -geometry 1280x800 -depth 24

# Wait until vncserver is actually listening on 5901
echo "Waiting for vncserver..."
for i in $(seq 1 20); do
    if ss -tlnp | grep -q 5901; then
        echo "vncserver ready"
        break
    fi
    sleep 1
done

# Now start noVNC
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 --web /usr/share/novnc &
echo "noVNC started"
