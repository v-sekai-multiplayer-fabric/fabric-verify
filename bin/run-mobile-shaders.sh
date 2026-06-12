#!/usr/bin/env bash
# Regression: the mobile rendering method under precision=double compiles all
# scene shader variants (feat/double-precision-mobile). Headless via xvfb.
set -euo pipefail
errs=$(timeout 60 xvfb-run -a -s "-screen 0 640x480x24" \
  "$GODOT" --path /assets/loop_game --rendering-method mobile --rendering-driver vulkan --quit-after 120 2>&1 \
  | grep -cE 'Error compiling|no matching overloaded' || true)
[ "$errs" -eq 0 ] && echo "MOBILE+DOUBLE SHADERS PASS: zero compile errors" || { echo "FAIL: $errs shader errors"; exit 1; }
