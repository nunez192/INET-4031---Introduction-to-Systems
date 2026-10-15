# Week 6, GitHub Actions and Observability

## What this does
- A GitHub Actions workflow (`.github/workflows/opentofu-checks.yml`) that runs `tofu fmt -check`, `tofu init`, and `tofu validate` on every pull request that changes `week-5/`.
- Prometheus on the local k3s cluster, installed with Helm from the `prometheus` chart, plus `pq.sh`, a small script that asks it questions.

## Requirements
- Helm
- The Week 5 stack running on k3s
- `gh` signed in with the `workflow` scope, to push workflow files

## Install Prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  --version 29.35.0 \
  --namespace monitoring \
  --create-namespace \
  --values week-6/prometheus-values.yaml
## Ask it a question
kubectl port-forward --namespace monitoring service/prometheus-server 9090:80
./week-6/pq.sh 'up'
