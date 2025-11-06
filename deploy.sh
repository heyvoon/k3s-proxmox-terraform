#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}K3s on Proxmox Deployment Script${NC}"
echo -e "${GREEN}================================${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars not found!${NC}"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}Ansible not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y ansible
fi

# Step 1: Initialize Terraform
echo -e "\n${GREEN}Step 1: Initializing Terraform...${NC}"
terraform init

# Step 2: Validate configuration
echo -e "\n${GREEN}Step 2: Validating Terraform configuration...${NC}"
terraform validate

# Step 3: Plan deployment
echo -e "\n${GREEN}Step 3: Planning deployment...${NC}"
terraform plan

# Ask for confirmation
echo -e "\n${YELLOW}Do you want to proceed with the deployment? (yes/no)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}Deployment cancelled.${NC}"
    exit 0
fi

# Step 4: Apply Terraform
echo -e "\n${GREEN}Step 4: Creating VMs with Terraform...${NC}"
terraform apply -auto-approve

# Get the K3s token
echo -e "\n${GREEN}Step 5: Retrieving K3s token...${NC}"
export K3S_TOKEN=$(terraform output -raw k3s_token)
echo "K3s Token: ${K3S_TOKEN}"

# Wait for VMs to be ready
echo -e "\n${GREEN}Step 6: Waiting for VMs to boot (60 seconds)...${NC}"
sleep 60

# Test SSH connectivity
echo -e "\n${GREEN}Step 7: Testing SSH connectivity...${NC}"
CONTROL_PLANE_IP=$(terraform output -json control_plane_ips | jq -r '.[0]')
echo "Testing connection to ${CONTROL_PLANE_IP}..."

retries=0
max_retries=30
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@${CONTROL_PLANE_IP} "echo 'SSH OK'" &> /dev/null; do
    retries=$((retries+1))
    if [ $retries -ge $max_retries ]; then
        echo -e "${RED}Failed to connect via SSH after ${max_retries} attempts${NC}"
        exit 1
    fi
    echo "Waiting for SSH... (attempt $retries/$max_retries)"
    sleep 10
done

echo -e "${GREEN}SSH connectivity confirmed!${NC}"

# Step 8: Install K3s using Ansible
echo -e "\n${GREEN}Step 8: Installing K3s cluster with Ansible...${NC}"
cd ansible
ansible-playbook -i inventory.yml k3s-install.yml
cd ..

# Step 9: Display cluster info
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"

echo -e "\n${GREEN}Cluster Information:${NC}"
terraform output cluster_info

echo -e "\n${GREEN}To access your cluster:${NC}"
echo "1. Export kubeconfig:"
echo -e "   ${YELLOW}export KUBECONFIG=$(pwd)/kubeconfig${NC}"
echo ""
echo "2. Test cluster access:"
echo -e "   ${YELLOW}kubectl get nodes${NC}"
echo ""
echo "3. SSH to control plane:"
echo -e "   ${YELLOW}$(terraform output -raw ssh_command_control_plane)${NC}"
echo ""
echo -e "${GREEN}Kubeconfig saved to: $(pwd)/kubeconfig${NC}"