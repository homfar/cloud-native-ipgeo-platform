#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"
OUTPUT_FILE="$ROOT_DIR/ansible/inventory.ini"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/ipgeo-platform}"

nodes_json="$(terraform -chdir="$TF_DIR" output -json nodes)"

cp_public="$(jq -r '.["sre-cp-01"].public_ip' <<<"$nodes_json")"
worker1_public="$(jq -r '.["sre-worker-01"].public_ip' <<<"$nodes_json")"
worker2_public="$(jq -r '.["sre-worker-02"].public_ip' <<<"$nodes_json")"

cat > "$OUTPUT_FILE" <<EOF
[control_plane]
sre-cp-01 ansible_host=$cp_public private_ip=10.10.0.10

[workers]
sre-worker-01 ansible_host=$worker1_public private_ip=10.10.0.11
sre-worker-02 ansible_host=$worker2_public private_ip=10.10.0.12

[k8s_cluster:children]
control_plane
workers

[k8s_cluster:vars]
ansible_user=root
ansible_ssh_private_key_file=$SSH_KEY
EOF

chmod 600 "$OUTPUT_FILE"
echo "Created $OUTPUT_FILE"
