#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$ROOT_DIR/kubeconfig}"

kubectl get nodes -o wide
kubectl get pods -A
kubectl -n database get cluster
kubectl -n monitoring get prometheus,alertmanager
kubectl -n app get deployment,service,servicemonitor
