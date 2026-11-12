#!/usr/bin/env bash
# Print one number from a saved k6 run.
# Usage: ./week-10/k6-stat.sh <label> <p50|p95|rps>

set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <label> <p50|p95|rps>" >&2
  exit 2
fi

FILE="$HOME/.k6-$1.json"
if [ ! -f "$FILE" ]; then
  echo "There is no saved run called '$1' ($FILE)." >&2
  exit 1
fi

python3 - "$FILE" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["metrics"]
pick = {
    "p50": lambda: f"{d['http_req_duration']['med']:.0f}",
    "p95": lambda: f"{d['http_req_duration']['p(95)']:.0f}",
    "rps": lambda: f"{d['http_reqs']['rate']:.1f}",
}
if sys.argv[2] not in pick:
    sys.exit("Pick one of: p50, p95, rps")
print(pick[sys.argv[2]]())
PY
