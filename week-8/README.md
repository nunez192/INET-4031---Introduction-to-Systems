# Week 8: Security Hardening and Shifting Left

## What This Does

- Hardens the web container by running it as user 10001 instead of root.
- Prevents privilege escalation and removes unnecessary capabilities.
- Adds CPU and memory limits to the web and database containers.
- Uses a NetworkPolicy to allow only web pods to connect to the database.
- Adds security scanning to GitHub pull requests.
- Uses a GitHub ruleset to require successful checks before merging.
- Adds a deployment safety check to detect destructive infrastructure changes.
- Protects sensitive files using restricted permissions.

## What Lives Where

| Location | Components | Survives VM Deletion? |
| --- | --- | --- |
| GitHub | Ruleset and workflow | Yes |
| Repository | OpenTofu files, deploy script, ruleset.json | Yes |
| Ubuntu VM | File permissions and cron configuration | No |

## Rebuild the VM Side

After rebuilding the VM and restoring the Week 7 environment:

chmod 600 week-5/terraform.tfstate* ~/deploy.log ~/.deployed-commit

If the GitHub ruleset is missing, recreate it using:

gh api --method POST repos/{owner}/{repo}/rulesets --input week-8/ruleset.json

## Check the Security Settings

kubectl exec deploy/web -- id

kubectl get networkpolicy

gh api repos/{owner}/{repo}/rulesets

grep BLOCKED ~/deploy.log | tail -n 3

## Known Limitations

SSH still allows password authentication, and there is no host firewall. The OpenTofu state file contains sensitive information. The database container still runs as root, and the security scan only checks a limited number of rules.

## Week 8 Recovery Note

During the destructive deployment test, an older deployment command attempted to replace the database volume before the safety check ran. The deployment script was corrected, automatic deployment was disabled, and a PostgreSQL backup was created. Database storage recovery still requires verification before deployment can resume.
