#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}K3s Proxmox Setup Script${NC}"
echo -e "${GREEN}================================${NC}"

# Create directory structure
echo -e "\n${GREEN}Creating directory structure...${NC}"
mkdir -p ansible

# Create files
echo -e "${GREEN}Creating configuration files...${NC}"

# Copy tfvars example to actual file if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${YELLOW}Created terraform.tfvars - Please edit it with your token secret!${NC}"
else
    echo -e "${YELLOW}terraform.tfvars already exists${NC}"
fi

# Make scripts executable
chmod +x deploy.sh 2>/dev/null || true
chmod +x setup.sh 2>/dev/null || true

# Check prerequisites
echo -e "\n${GREEN}Checking prerequisites...${NC}"

# Check Terraform
if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✓ Terraform installed: $(terraform version -json | jq -r '.terraform_version')${NC}"
else
    echo -e "${YELLOW}✗ Terraform not found. Installing...${NC}"
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform -y
fi

# Check Ansible
if command -v ansible &> /dev/null; then
    echo -e "${GREEN}✓ Ansible installed: $(ansible --version | head -n1)${NC}"
else
    echo -e "${YELLOW}✗ Ansible not found (will be installed during deployment)${NC}"
fi

# Check jq
if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓ jq installed${NC}"
else
    echo -e "${YELLOW}✗ jq not found. Installing...${NC}"
    sudo apt update && sudo apt install jq -y
fi

# Check SSH key
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo -e "${GREEN}✓ SSH key found${NC}"
    echo "  $(cat $HOME/.ssh/id_ed25519.pub)"
else
    echo -e "${YELLOW}✗ SSH key not found${NC}"
    echo "  Generate one with: ssh-keygen -t ed25519 -C 'k3s-cluster'"
fi

# Test Proxmox connectivity
echo -e "\n${GREEN}Testing Proxmox connectivity...${NC}"
PVE_IP="192.168.1.200"
if ping -c 1 $PVE_IP &> /dev/null; then
    echo -e "${GREEN}✓ Proxmox host is reachable${NC}"
else
    echo -e "${YELLOW}✗ Cannot reach Proxmox host at $PVE_IP${NC}"
fi

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Setup Summary${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit terraform.tfvars and add your Proxmox API token secret"
echo "   nano terraform.tfvars"
echo ""
echo "2. Review the configuration:"
echo "   cat terraform.tfvars"
echo ""
echo "3. Run the deployment:"
echo "   ./deploy.sh"
echo ""
echo -e "${GREEN}Files created:${NC}"
ls -lh *.tf *.sh terraform.tfvars* ansible/*.yml 2>/dev/null || true