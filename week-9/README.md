# Week 9, Data Observability and Backup

## What this does
- `week-5/exporter.tf` runs a Postgres exporter, so Prometheus can report whether the database is up, how big it is, and how many rows each table has. `week-5/network.tf` lets only the web pods and the exporter connect to the database.
- `week-9/backup.sh` dumps the database to `~/backups` every five minutes (cron), checks each dump, and keeps the newest 12. It will not replace good backups with a dump of an empty database.
- `week-9/restore.sh` restores a backup into the running database. `week-9/sql.sh` runs SQL in the database pod, and `week-9/check.sh` checks the whole setup.

## What lives where
| Where | What | Survives deleting the VM? |
| --- | --- | --- |
| This repository | The scripts, the OpenTofu files, this README | Yes |
| My own computer | A copy of one backup, made by hand | Yes, but only as fresh as my last copy |
| The VM | `~/backups`, the cron line, the database volume | No |
| Prometheus | The database metrics | No, they are lost when its pod restarts |

## Runbook: restore the database
- **Incident:** every table in the database is gone.
- **Symptom:** the app shows errors or no tickets, and `./week-9/sql.sh` prints `(no tables)`. Prometheus stops reporting the table's row count while `pg_up` stays 1.
- **Fix:**
  1. List the backups with `ls -1t ~/backups`, and pick one taken before the data was lost.
  2. Restore it with `./week-9/restore.sh ~/backups/<file>`.
  3. Check the rows with `./week-9/sql.sh`.
- **Measured in the drill:**
  - Rows before: tickets: 3 
  - Age of the backup used: 58 seconds (target: 5 minutes)
  - Recovery time: 33 seconds (target: 10 minutes)

## Rebuild on a fresh VM
The cron lines, the backups and the database volume live on the VM, so a new VM starts without them.
1. Finish the Week 7 and Week 8 rebuild steps, so the stack, the deploy and the cron job are back.
2. Make a private folder for the backups: `mkdir -m 700 ~/backups`.
3. From my own computer, copy a backup to the VM: `scp -P 2222 <file> <username>@127.0.0.1:backups/`.
4. Restore it: `./week-9/restore.sh ~/backups/<file>`.
5. Put the backup schedule back, from the repository root: `( crontab -l 2>/dev/null; echo "*/5 * * * * $PWD/week-9/backup.sh >> $HOME/backup.log 2>&1" ) | crontab -`

## Known limitations
The backups are not encrypted, and the copy off the VM is manual. The exporter connects as the database superuser. Nothing alerts me when `pg_up` drops or when backups stop. The drill restored into the same cluster, so a restore onto a new VM is untested. The Postgres image is a floating tag.
