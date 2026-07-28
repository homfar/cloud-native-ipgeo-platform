#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$ROOT_DIR/kubeconfig}"

if [[ -f "$KUBECONFIG" ]]; then
  kubectl delete namespace app database monitoring cnpg-system --ignore-not-found --wait=false || true
fi

terraform -chdir="$ROOT_DIR/terraform" destroy
