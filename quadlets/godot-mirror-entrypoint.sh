#!/bin/bash
# Run the Godot editor inside the container on a self-contained Xvnc framebuffer and mirror it over
# VNC (no dependency on the host compositor, so the Wayland embedder issue can't bite). Connect with
# any VNC viewer to localhost:$VNC_PORT.
set -e
PORT="${VNC_PORT:-5901}"
GEO="${VNC_GEOMETRY:-1600x900}"
GODOT=/chibifire-assets-2026w24/files/loot-action-vertical-slice/godot/bin/godot.linuxbsd.editor.dev.x86_64
PROJECT=/chibifire-assets-2026w24/files/loot-action-vertical-slice/vrm-game-project

# Xvnc = X server + VNC server in one process
Xvnc :99 -geometry "$GEO" -depth 24 -rfbport "$PORT" -SecurityTypes None -AlwaysShared -NeverShared=0 >/tmp/xvnc.log 2>&1 &
export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1   # llvmpipe — robust without GPU passthrough
sleep 2
exec "$GODOT" --display-driver x11 --rendering-driver opengl3 --path "$PROJECT" -e
