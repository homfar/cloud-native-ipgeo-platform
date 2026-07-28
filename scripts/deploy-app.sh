#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$ROOT_DIR/kubeconfig}"

: "${APP_IMAGE:?Set APP_IMAGE, for example ghcr.io/GITHUB_USERNAME/ipgeo-api:v1.0.0}"
: "${DB_PASSWORD:?Set DB_PASSWORD before running this script}"

kubectl apply -f "$ROOT_DIR/kubernetes/namespaces.yaml"

# PostgreSQL bootstrap secret is created separately and must not have its
# immutable type changed during application deployment.
if ! kubectl -n database get secret app-db-secret >/dev/null 2>&1; then
  kubectl -n database create secret generic app-db-secret \
    --from-literal=username=app \
    --from-literal=password="$DB_PASSWORD"
else
  echo "Reusing existing database/app-db-secret."
fi

# The application runs in a separate namespace, so it needs its own copy
# of the database credentials.
kubectl -n app create secret generic app-db-secret \
  --from-literal=username=app \
  --from-literal=password="$DB_PASSWORD" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

kubectl apply -f "$ROOT_DIR/kubernetes/postgres-cluster.yaml"
kubectl -n database wait \
  --for=condition=Ready \
  cluster/postgres \
  --timeout=15m

sed "s|IMAGE_PLACEHOLDER|$APP_IMAGE|g" \
  "$ROOT_DIR/kubernetes/app.yaml" |
kubectl apply -f -

kubectl -n app rollout status \
  deployment/ipgeo-api \
  --timeout=5m

echo "Application is deployed."
