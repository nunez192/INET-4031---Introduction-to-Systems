#!/usr/bin/env bash
# Check this week's setup and print PASS or FAIL for each item.
# Usage: ./week-10/check.sh

set -u

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
failed=0
ok()  { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; failed=1; }

# Run one SQL statement in the database pod and print just the value.
q() { printf '%s\n' "$1" | kubectl exec -i deploy/db -- sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA' 2>/dev/null; }

# 1. k6 is installed.
if command -v k6 >/dev/null 2>&1; then
  ok "k6 is installed"
else
  bad "k6 is not installed"
fi

# 2. pg_stat_statements is loaded at startup and created in your database.
preload="$(q 'SHOW shared_preload_libraries' || true)"
ext="$(q "SELECT count(*) FROM pg_extension WHERE extname = 'pg_stat_statements'" || true)"
if printf '%s\n' "$preload" | grep -q pg_stat_statements && [ "$ext" = "1" ]; then
  ok "pg_stat_statements is loaded and created"
else
  bad "pg_stat_statements is not set up (loaded: '$preload', created: '$ext')"
fi

# 3. The status index exists.
idx="$(q "SELECT count(*) FROM pg_indexes WHERE indexname = 'idx_tickets_status_created'" || true)"
if [ "$idx" = "1" ]; then
  ok "the index idx_tickets_status_created exists"
else
  bad "the index idx_tickets_status_created does not exist"
fi

# 4. The live page is bounded: it shows at most 50 tickets, however many are in the table.
ip="$(kubectl get service web -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
page="$(curl -s -m 30 "http://${ip}:8080/" 2>/dev/null || true)"
rows="$(printf '%s' "$page" | grep -c '<tr class="status-' || true)"
if [ -n "$page" ] && [ "$rows" -le 50 ]; then
  ok "the live page shows $rows tickets (at most 50)"
else
  bad "the live page is not bounded, or did not answer (rows on the page: $rows)"
fi

# 5 and 6. The web Deployment runs the v2 image with its 500m CPU limit, in the cluster and in the file.
live_cpu="$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)"
live_image="$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$live_cpu" = "500m" ] && grep -q 'cpu    = "500m"' "$ROOT/week-5/web.tf"; then
  ok "the web CPU limit is 500m in the cluster and in week-5/web.tf"
else
  bad "the web CPU limit is '$live_cpu' in the cluster, and should be 500m in the cluster and in week-5/web.tf"
fi
if [ "${live_image##*:}" = "v2" ] && grep -q 'week-4-web:v2' "$ROOT/week-5/web.tf"; then
  ok "web runs the v2 image, in the cluster and in week-5/web.tf"
else
  bad "web runs '$live_image' in the cluster, and should run week-4-web:v2 in the cluster and in week-5/web.tf"
fi

# 7. OpenTofu and the cluster agree. Exit code 0 means no changes, and 2 means changes are pending.
( cd "$ROOT/week-5" && tofu plan -input=false -lock=false -detailed-exitcode >/dev/null 2>&1 )
rc=$?
if [ "$rc" -eq 0 ]; then
  ok "tofu plan finds no drift"
elif [ "$rc" -eq 2 ]; then
  bad "tofu plan shows changes: the cluster has drifted from your files"
else
  bad "tofu plan could not run (exit code $rc)"
fi

# 8. The performance gate workflow is in the repository, and the smoke test has its threshold.
if [ -f "$ROOT/.github/workflows/load-test.yml" ] && grep -q 'p(95)<500' "$HERE/smoke-test.js"; then
  ok "the load-test workflow is in the repository, and the smoke test has its p95 threshold"
else
  bad ".github/workflows/load-test.yml is missing, or smoke-test.js has no p(95)<500 threshold"
fi

# 9. The last ramped test, after the CPU limit was restored, stayed under 500 ms at the 95th percentile.
p95="$("$HERE/k6-stat.sh" restored p95 2>/dev/null || true)"
if [ -n "$p95" ] && [ "$p95" -lt 500 ]; then
  ok "the saved 'restored' ramped test had a p95 of $p95 ms"
else
  bad "there is no saved 'restored' ramped test under 500 ms (p95: '${p95:-none}')"
fi

if [ "$failed" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
  exit 1
fi
