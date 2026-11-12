#!/usr/bin/env bash
# Run a k6 test against your web Service, save the result, and print a one-line summary.
# Usage: ./week-10/run-k6.sh <test-file> <label>
#   For example: ./week-10/run-k6.sh week-10/smoke-test.js baseline

set -eu

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <test-file> <label>" >&2
  exit 2
fi

TEST="$1"
LABEL="$2"
OUT="$HOME/.k6-$LABEL.json"

IP="$(kubectl get service web -o jsonpath='{.spec.clusterIP}')"
export BASE_URL="http://${IP}:8080"

status=0
k6 run --quiet --no-color --summary-export="$OUT" "$TEST" || status=$?

python3 - "$OUT" "$LABEL" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["metrics"]
dur, reqs = d["http_req_duration"], d["http_reqs"]
kb = d["data_received"]["count"] / max(reqs["count"], 1) / 1024
print(f"{sys.argv[2]}: p50 {dur['med']:.0f} ms | p95 {dur['p(95)']:.0f} ms | {reqs['rate']:.1f} requests/s | "
      f"{d['http_req_failed']['value'] * 100:.1f}% failed | {kb:.0f} KB per response")
PY

if [ "$status" -eq 0 ]; then
  echo "Thresholds: all passed."
else
  echo "Thresholds: at least one FAILED (k6 exit code $status)."
fi
exit "$status"
