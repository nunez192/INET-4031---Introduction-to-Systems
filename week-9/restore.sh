#!/usr/bin/env bash
# Restore the database from a backup file.
# Usage: ./week-9/restore.sh [backup-file]
# With no file, it uses the newest backup in ~/backups.

set -eu

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

FILE="${1:-}"
if [ -z "$FILE" ]; then
  FILE="$(ls -1t "$HOME"/backups/db-*.dump 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$FILE" ] || [ ! -s "$FILE" ]; then
  echo "No backup file found. Pass one as an argument: ./week-9/restore.sh ~/backups/<file>" >&2
  exit 1
fi

echo "Restoring from $FILE"
kubectl exec -i deploy/db -- sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --exit-on-error' < "$FILE"

echo "Restore finished. Rows now:"
"$(dirname "$0")/sql.sh"
