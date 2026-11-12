#!/usr/bin/env bash
# Ask Prometheus in what share of its CPU periods the web container was held back by its CPU limit.
# Needs the Prometheus port-forward from Week 6. Usage: ./week-10/throttle.sh <label>

set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <label>" >&2
  exit 2
fi

QUERY='sum(rate(container_cpu_cfs_throttled_periods_total{container="web"}[3m])) / sum(rate(container_cpu_cfs_periods_total{container="web"}[3m]))'
answer="$("$HERE/../week-6/pq.sh" "$QUERY")"
value="$(printf '%s\n' "$answer" | awk '/->/ {print $NF}' | head -n 1)"

if [ -z "$value" ]; then
  echo "Prometheus has no CPU-period data for the web container yet. Wait a minute and try again." >&2
  exit 1
fi

percent="$(python3 -c 'import math, sys
v = float(sys.argv[1])
print(0 if math.isnan(v) else round(v * 100))' "$value")"

echo "$percent" > "$HOME/.throttle-$1"
echo "$1: the web container was held back by its CPU limit in $percent% of its CPU periods"
