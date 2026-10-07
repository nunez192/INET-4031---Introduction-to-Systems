# Week 5, Infrastructure as Code with OpenTofu

## What this does
Defines the Week 4 stack (Flask web app, PostgreSQL, storage, configuration, and secrets) as OpenTofu resources on a local k3s cluster.

## Requirements
- OpenTofu
- A running k3s cluster and `~/.kube/config`
- The `week-4-web:latest` image imported into k3s
- A `terraform.tfvars` file in `week-5/`

## Deploy
tofu init
tofu plan
tofu apply

## Verify
kubectl get pods
tofu output -raw port_forward_command

Run the command it prints, then visit http://localhost:8080 in a browser.

## Tear down
tofu destroy

This deletes the database volume along with everything else.

## Known limitation
`terraform.tfstate` holds the database password and the Flask secret key in plain text. It is gitignored, not encrypted.
