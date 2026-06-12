#!/usr/bin/env bash
set -euo pipefail
timeout 90 "$GODOT" --headless --script /assets/contention_server.gd > /tmp/srv.log 2>&1 &
SRV=$!
until grep -q 'CONTSRV ready' /tmp/srv.log || ! kill -0 $SRV; do sleep 0.5; done
for i in 1 2 3 4; do
  CONT_GOLDEN=/assets/contention_golden.csv PLAYER_ID=$i \
    timeout 90 "$GODOT" --headless --script /assets/contention_client.gd > /tmp/c$i.log 2>&1 &
done
wait %2 %3 %4 %5 2>/dev/null || true
kill $SRV 2>/dev/null || true
pass=0
for i in 1 2 3 4; do grep -q 'PASS' /tmp/c$i.log && pass=$((pass+1)); done
grep -qiE 'double free|corrupt' /tmp/srv.log && { echo "SERVER CRASH"; exit 1; }
[ $pass -eq 4 ] && echo "FOUR-PLAYER PER-CLIENT PASS: 4/4 clients verified their own announcements"
[ $pass -eq 4 ]
