#!/usr/bin/env bash
set -euo pipefail
"$GODOT" --headless --script /assets/contention_server.gd > /tmp/srv.log 2>&1 &
SRV=$!
until grep -q 'CONTSRV ready' /tmp/srv.log || ! kill -0 $SRV; do sleep 0.5; done
for i in 1 2 3 4; do
  CONT_GOLDEN=/assets/contention_golden.csv PLAYER_ID=$i \
    "$GODOT" --headless --script /assets/contention_client.gd > /tmp/c$i.log 2>&1 &
done
wait %2 %3 %4 %5 2>/dev/null || true
until grep -q 'CONTSRV done' /tmp/srv.log || ! kill -0 $SRV; do sleep 0.5; done
kill $SRV 2>/dev/null || true
grep -oE 'RESOLVED [0-9]+:[0-9]+' /tmp/srv.log | sed 's/RESOLVED //' | sort -t: -k1 -n > /tmp/wire.txt
tail -n +2 /assets/contention_golden.csv | awk -F, '{print $1":"$6}' | sort -t: -k1 -n > /tmp/gold.txt
diff -q /tmp/wire.txt /tmp/gold.txt && echo "FOUR-PLAYER CONTENTION PASS: $(wc -l < /tmp/wire.txt) rounds"
