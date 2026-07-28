SHELL := /bin/bash
TF_DIR := terraform
ANSIBLE_CONFIG := ansible/ansible.cfg
export ANSIBLE_CONFIG
KUBECONFIG := $(CURDIR)/kubeconfig
export KUBECONFIG

.PHONY: help tf-init tf-plan tf-apply inventory cluster platform app check destroy

help:
	@echo "tf-init    - initialize Terraform"
	@echo "tf-plan    - show Terraform plan"
	@echo "tf-apply   - create Hetzner resources"
	@echo "inventory  - create Ansible inventory from Terraform outputs"
	@echo "cluster    - install Kubernetes with Ansible"
	@echo "platform   - install storage, monitoring and PostgreSQL operator"
	@echo "app        - deploy PostgreSQL and the API"
	@echo "check      - show important resource status"
	@echo "destroy    - remove workloads and Hetzner resources"

tf-init:
	terraform -chdir=$(TF_DIR) init

tf-plan:
	terraform -chdir=$(TF_DIR) fmt -check
	terraform -chdir=$(TF_DIR) validate
	terraform -chdir=$(TF_DIR) plan

tf-apply:
	terraform -chdir=$(TF_DIR) apply

inventory:
	./scripts/generate-inventory.sh

cluster:
	ansible-playbook -i ansible/inventory.ini ansible/site.yml

platform:
	./scripts/install-platform.sh

app:
	./scripts/deploy-app.sh

check:
	./scripts/check.sh

destroy:
	./scripts/destroy.sh
