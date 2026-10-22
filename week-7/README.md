# Week 7, Continuous Delivery

## What this does
- `.github/workflows/deploy-gate.yml` runs on every push to `main`, on GitHub's machines. One job checks the OpenTofu files in `week-5/`, and the other renders the Prometheus chart with `week-6/prometheus-values.yaml`.
- `week-7/deploy.sh` checks GitHub for a new commit on `main`. If the gate passed for that commit, it runs `tofu apply` for the app and `helm upgrade --install` for Prometheus.
- A cron job runs the script every two minutes. The VM connects out to GitHub, and GitHub never connects in. If the VM was off, the first run after it boots catches up.
- A guard at the start of every deploy refuses to continue if the working copy is not on `main`, has uncommitted changes to tracked files, or has commits that are not on GitHub.
- The repository is public, and no workflow in it runs on the VM.

## Requirements
- The Week 5 app and the Week 6 Prometheus running on k3s
- `tofu`, `helm`, `kubectl` and `gh` (logged in) on the VM
- The cron service running, and a cron line for `week-7/deploy.sh` (see below)

## Deploy
Merge a pull request, wait for the gate, and wait up to two minutes. To deploy right away:

    ./week-7/deploy.sh

## Roll back
Revert the merge commit, open a pull request with the revert, and merge it:

    git revert -m 1 <merge-commit>

## Check on it

    crontab -l
    tail -n 20 ~/deploy.log
    gh run list --workflow deploy-gate.yml --limit 3

## Rebuild on a fresh VM
The cron line, the record of the last deploy and `week-5/terraform.tfvars` live on the VM, not in this repository. On a new VM:

1. Install k3s, OpenTofu, Helm and `gh` as in Weeks 3 to 6, and run `gh auth login`.
2. Clone this repository, copy `week-5/terraform.tfvars.example` to `week-5/terraform.tfvars`, and fill in real values.
3. Import the `week-4-web` image into k3s as in Week 4.
4. Run `./week-7/deploy.sh`. A new VM has no record of a previous deploy, so it deploys the current `main`.
5. From the repository root, add the schedule:

    ( crontab -l 2>/dev/null; echo "*/2 * * * * $PWD/week-7/deploy.sh >> $HOME/deploy.log 2>&1" ) | crontab -

## Known limitations
The deploy runs from a folder that I also edit, and the state file and variable values live on this one VM. Nothing asks a person before `tofu apply` runs, and the gate only catches what its checks look for. The job runs as my own user, so anything that gets a commit onto `main` and past the gate runs commands as me.
