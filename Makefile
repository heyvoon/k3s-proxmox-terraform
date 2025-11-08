.PHONY: help setup init plan apply deploy destroy clean status ssh logs kubeconfig test

# Default target
help:
	@echo "K3s on Proxmox - Available Commands:"
	@echo ""
	@echo "  make setup       - Run initial setup and check prerequisites"
	@echo "  make init        - Initialize Terraform"
	@echo "  make plan        - Show Terraform plan"
	@echo "  make apply       - Create VMs with Terraform"
	@echo "  make deploy      - Full deployment (Terraform + Ansible)"
	@echo "  make destroy     - Destroy all resources"
	@echo "  make clean       - Clean Terraform files"
	@echo ""
	@echo "  make status      - Show cluster status"
	@echo "  make ssh         - SSH to control plane"
	@echo "  make logs        - View K3s logs on control plane"
	@echo "  make kubeconfig  - Export kubeconfig"
	@echo "  make test        - Deploy test nginx application"
	@echo ""

setup:
	@echo "Running setup..."
	./setup.sh

init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

plan: init
	@echo "Planning deployment..."
	cd terraform && terraform plan

apply: init
	@echo "Applying Terraform configuration..."
	cd terraform && terraform apply

deploy:
	@echo "Running full deployment..."
	./deploy.sh

destroy:
	@echo "Destroying infrastructure..."
	cd terraform && terraform destroy

clean:
	@echo "Cleaning Terraform files..."
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate* *.log

status:
	@echo "Cluster Status:"
	@export KUBECONFIG=$(shell pwd)/kubeconfig && kubectl get nodes -o wide
	@echo ""
	@export KUBECONFIG=$(shell pwd)/kubeconfig && kubectl get pods -A

ssh:
	@echo "Connecting to control plane..."
	@ssh ubuntu@192.168.1.180

logs:
	@echo "K3s logs from control plane:"
	@ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -n 50"

kubeconfig:
	@echo "Kubeconfig location: $(shell pwd)/kubeconfig"
	@echo ""
	@echo "Export with:"
	@echo "export KUBECONFIG=$(shell pwd)/kubeconfig"

test:
	@echo "Deploying test nginx application..."
	@export KUBECONFIG=$(shell pwd)/kubeconfig && \
		kubectl create deployment nginx --image=nginx && \
		kubectl expose deployment nginx --port=80 --type=NodePort && \
		kubectl get svc nginx
	@echo ""
	@echo "Access nginx at: http://192.168.1.185:<NodePort>"

# Show Terraform outputs
outputs:
	@cd terraform && terraform output

# Get K3s token
token:
	@cd terraform && terraform output -raw k3s_token

# Ping all nodes
ping:
	@echo "Pinging control plane..."
	@ping -c 1 192.168.1.180 > /dev/null && echo "✓ Control plane (192.168.1.180)" || echo "✗ Control plane unreachable"
	@echo "Pinging workers..."
	@ping -c 1 192.168.1.185 > /dev/null && echo "✓ Worker 1 (192.168.1.185)" || echo "✗ Worker 1 unreachable"
	@ping -c 1 192.168.1.186 > /dev/null && echo "✓ Worker 2 (192.168.1.186)" || echo "✗ Worker 2 unreachable"
	@ping -c 1 192.168.1.187 > /dev/null && echo "✓ Worker 3 (192.168.1.187)" || echo "✗ Worker 3 unreachable"

# Quick cluster info
info:
	@echo "=== Cluster Information ==="
	@cd terraform && terraform output -json cluster_info | jq .
	@echo ""
	@echo "=== Node IPs ==="
	@echo "Control Plane: $(shell cd terraform && terraform output -json control_plane_ips | jq -r '.[]')"
	@echo "Workers: $(shell cd terraform && terraform output -json worker_ips | jq -r '.[]')"