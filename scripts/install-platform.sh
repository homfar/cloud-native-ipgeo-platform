#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$ROOT_DIR/kubeconfig}"
: "${GRAFANA_PASSWORD:?Set GRAFANA_PASSWORD before running this script}"

kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.36/deploy/local-path-storage.yaml"
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add cnpg https://cloudnative-pg.github.io/charts --force-update
helm repo update

helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --version 87.15.2 \
  --values "$ROOT_DIR/kubernetes/monitoring-values.yaml" \
  --set-string grafana.adminPassword="$GRAFANA_PASSWORD" \
  --wait

kubectl apply -f "$ROOT_DIR/kubernetes/namespaces.yaml"
kubectl apply -f "$ROOT_DIR/kubernetes/monitoring/ipgeo-prometheus-rules.yaml"
kubectl apply -f "$ROOT_DIR/kubernetes/dashboard.yaml"

echo "Platform components are installed."
