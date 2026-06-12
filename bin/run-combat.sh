#!/usr/bin/env bash
set -euo pipefail
timeout 90 "$GODOT" --headless --script /assets/combat_server.gd > /tmp/srv.log 2>&1 &
SRV=$!
until grep -q 'COMBATSRV ready' /tmp/srv.log || ! kill -0 $SRV; do sleep 0.5; done
COMBAT_GOLDEN=/assets/combat_golden.csv timeout 90 "$GODOT" --headless --script /assets/combat_client.gd 2>&1 | tee /tmp/cli.log
kill $SRV 2>/dev/null || true
grep -q 'COMBAT WIRE PARITY PASS' /tmp/cli.log
