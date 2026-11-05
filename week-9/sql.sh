#!/usr/bin/env bash
# Run SQL in the database pod. With no argument, print the row count of every table.
# Usage: ./week-9/sql.sh                    (row counts)
#        ./week-9/sql.sh 'SELECT version()' (any one statement)

set -eu

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

if [ "$#" -gt 1 ]; then
  echo "Usage: $0 ['SQL statement']" >&2
  exit 2
fi

psql_in_pod() {
  kubectl exec -i deploy/db -- sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 "$@"' sh "$@"
}

if [ "$#" -eq 1 ]; then
  printf '%s\n' "$1" | psql_in_pod
  exit 0
fi

counts="$(printf '%s\n' \
  "SELECT format('SELECT %L || '': '' || count(*) FROM %I.%I', relname, schemaname, relname) FROM pg_stat_user_tables ORDER BY relname \\gexec" \
  | psql_in_pod -tA)"

if [ -z "$counts" ]; then
  echo "(no tables)"
else
  echo "$counts"
fi
