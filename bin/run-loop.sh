#!/usr/bin/env bash
set -euo pipefail
DB=$(mktemp -u /tmp/loop_XXXX.db)
LOOP_DB=$DB timeout 170 "$GODOT" --headless --xr-mode off --script /assets/loop_game/server.gd > /tmp/srv.log 2>&1 &
SRV=$!
until grep -q 'LOOPSRV ready' /tmp/srv.log || ! kill -0 $SRV; do sleep 0.5; done
for i in 1 2 3 4; do
  BOT=1 BOT_NAME="bot$i" LOOP_HOST=127.0.0.1 timeout 150 "$GODOT" --headless --xr-mode off --path /assets/loop_game > /tmp/bot$i.log 2>&1 &
done
wait %2 %3 %4 %5 2>/dev/null || true
kill $SRV 2>/dev/null || true
grants=0
for i in 1 2 3 4; do grep -q 'outcome=GRANT' /tmp/bot$i.log && grants=$((grants+1)); done
grep -q 'LOOP COMPLETE' /tmp/srv.log && [ "$grants" -eq 1 ] \
  && echo "PLAYABLE LOOP PASS: full slice, exactly one grant" || { echo FAIL; exit 1; }
