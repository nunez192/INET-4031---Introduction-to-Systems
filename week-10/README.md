# Week 10, End-to-End Performance Investigation

## What this does
- `week-10/smoke-test.js` and `week-10/ramped-test.js` are k6 load tests of the web app. `week-10/run-k6.sh` runs one against the web Service, saves the result under a label, and prints a one-line summary. `week-10/k6-stat.sh` and `week-10/throttle.sh` read saved numbers back.
- `week-5/db.tf` loads `pg_stat_statements` when Postgres starts, so I can see which queries cost the most. `week-10/sql.sh` runs SQL in the database pod.
- `.github/workflows/load-test.yml` starts the app on a GitHub machine, adds 10,000 tickets, and fails a pull request whose p95 is over 500 ms. It is not a required check.
- `week-10/check.sh` checks the whole setup.

## What lives where
| Where | What | Survives deleting the VM? |
| --- | --- | --- |
| This repository | The test scripts, the workflow, the app and OpenTofu changes, this README | Yes |
| GitHub | The performance check on pull requests | Yes |
| The VM | k6, the saved results (`~/.k6-*.json` and `~/.throttle-*`), and the index I created by hand | No |
| Prometheus | The CPU, memory and throttling history | No, it is lost when its pod restarts |

## Runbook 1: the home page asks for every ticket
- **Symptom:** the p95 of the smoke test is over 500 ms after the table grows, the home page is several megabytes, and the web pods are throttled in most of their CPU periods even though their average CPU use is under the limit, because each request is a large burst of CPU work.
- **Root cause:** the home page runs `SELECT * FROM tickets ORDER BY id DESC` with no `LIMIT`. Postgres answers in a few milliseconds, but the web pod has to build a page with every ticket on it, so the work grows with the table.
- **Fix:**
  1. Confirm the query with `pg_stat_statements`. Its `rows` divided by `calls` is about the size of the table.
  2. Add `LIMIT 50` to the query in `week-4/app/app.py`.
  3. Build a new image tag, import it into k3s, and point `week-5/web.tf` at it.
  4. Ship it as a pull request, then run `./week-10/run-k6.sh week-10/smoke-test.js fixed`.
- **Measured:**
  - p95 with 10,000 extra tickets: 1280 ms
  - p95 after the fix: 85 ms
  - Share of CPU periods throttled during the slow test: 78%
  - Target: p95 under 500 ms

## Runbook 2: the web CPU limit is too low
- **Symptom:** the ramped test fails its p95 threshold even though the page is small, throughput drops, and the web pods' CPU use sits at their limit while Prometheus shows most of their CPU periods throttled.
- **Root cause:** the web Deployment's CPU limit was lowered by hand to 50m with `kubectl set resources`. The change was not in Git, so no pull request, gate or scan saw it. `tofu plan` shows it as drift.
- **Fix:**
  1. Confirm the limit with `kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}{"\n"}'`.
  2. See the drift with `cd week-5 && tofu plan`.
  3. Apply it back through OpenTofu with `tofu apply`, and check the limit prints `500m`.
  4. Run `./week-10/run-k6.sh week-10/ramped-test.js restored` and `./week-10/throttle.sh restored`.
- **Measured:**
  - p95 with the 50m limit: 7869 ms
  - p95 after restoring 500m: 86 ms
  - Share of CPU periods throttled with 50m: 91%
  - Share of CPU periods throttled after the fix: 7%
  - Target: p95 under 500 ms

## Known limitations
The home page shows only the newest 50 tickets and has no way to page through the rest. Nothing limits how often the page can be requested, and nothing alerts me about throttling. The index `idx_tickets_status_created` exists only in my database, not in code. The k6 tests run on the same VM as the cluster, so they compete with it. The performance check in GitHub is not required to merge, and it cannot see my cluster's CPU limits.
