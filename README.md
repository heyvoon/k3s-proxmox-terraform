# K3s on Proxmox VE with Terraform

This project deploys a K3s Kubernetes cluster on Proxmox VE using Terraform and Ansible.

## Architecture (Customizable)

- **Control Plane**: 1 node (2 vCPU, 4GB RAM, 15GB disk)
- **Workers**: 3 nodes (1 vCPU, 2GB RAM, 10GB disk each) - configurable
- **Total Resources**: 5 vCPU, 10GB RAM (configurable)
- **Network**: 192.168.1.180-187
- **Storage**: ZFS (local-zfs)
- **K3s Version**: v1.34.1+k3s1
- **Provider**: telmate/proxmox v3.0.2-rc05
- **QEMU Guest Agent**: Pre-installed and enabled on all nodes
- **Micro Editor**: Modern terminal text editor pre-installed

## Prerequisites

### On WSL/Linux:
```bash
# Terraform
terraform version  # Should be >= 1.0

# Ansible
ansible --version  # Will be installed by deploy script if missing

# SSH key
ls ~/.ssh/id_ed25519.pub  # Should exist

# jq (for parsing JSON)
sudo apt install jq
```

### On Proxmox:
- Ubuntu 24.04 cloud template (name: `ubuntu-24.04-cloud-tpl`)
- API token created: `root@pam!terraform`
- Available resources: 5+ vCPU, 10+ GB RAM
- ZFS storage pool: `local-zfs`
- Network bridge: `vmbr0`

## Quick Start

### 1. Clone and Setup

```bash
cd ~/k3s-proxmox-terraform
```

### 2. Configure Terraform Variables

```bash
# Copy example file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values (IMPORTANT!)
nano terraform/terraform.tfvars
```

**Required changes in `terraform/terraform.tfvars`:**
```hcl
proxmox_api_token_secret = "YOUR_ACTUAL_TOKEN_SECRET_HERE"
```

### 3. Deploy the Cluster

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The script will:
1. Initialize Terraform
2. Create VMs on Proxmox
3. Wait for VMs to boot
4. Install system utilities using Ansible
5. Install K3s using Ansible
6. Optional: Install ArgoCD for GitOps workflows
7. Save kubeconfig locally

### 4. Access Your Cluster

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Verify cluster
kubectl get nodes
kubectl get pods -A

# SSH to control plane
ssh ubuntu@192.168.1.180
```

### 5. Optional: Access ArgoCD (if installed)

If you chose to install ArgoCD during deployment:

```bash
# Port-forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access in browser: http://localhost:8080
# Username: admin
# Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
```

## Manual Deployment (Step by Step)

If you prefer to run each step manually:

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Plan Deployment
```bash
terraform plan
```

### Step 3: Apply Configuration
```bash
terraform apply
```

### Step 4: Get K3s Token
```bash
export K3S_TOKEN=$(terraform output -raw k3s_token)
echo $K3S_TOKEN
```

### Step 5: Wait for VMs
```bash
# Wait 60 seconds for VMs to boot
sleep 60

# Test SSH
ssh ubuntu@192.168.1.180 "echo 'SSH OK'"
```

### Step 6: Install System Utilities
```bash
cd ansible
ansible-playbook -i inventory.yml system-utils-install.yml
cd ..
```

### Step 7: Install K3s
```bash
cd ansible
ansible-playbook -i inventory.yml k3s-install.yml
cd ..
```

### Step 8: Optional: Install ArgoCD
```bash
cd ansible
ansible-playbook -i inventory.yml argocd-install.yml
cd ..
```

### Step 9: Use Your Cluster
```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

## Project Structure

```
k3s-proxmox-terraform/
├── terraform/
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output definitions
│   ├── terraform.tfvars.example # Example variables file
│   └── terraform.tfvars         # Your actual variables (gitignored)
├── ansible/
│   ├── inventory.yml            # Ansible inventory
│   ├── k3s-install.yml          # K3s installation playbook
│   ├── system-utils-install.yml # System utilities installation playbook
│   └── argocd-install.yml       # ArgoCD installation playbook
├── deploy.sh                    # Automated deployment script
├── setup.sh                     # Setup script
└── README.md                    # This file
```

## Customization

### Change Cluster Size

Edit `terraform.tfvars`:

```hcl
# Add more workers
worker_count = 5

# More resources per worker
worker_cpu = 2
worker_memory = 4096
worker_disk_size = "20G"

# High availability control plane
control_plane_count = 3
control_plane_cpu = 4
control_plane_memory = 8192
control_plane_disk_size = "30G"
```

**Important:** When changing `worker_count`, you must also update the Ansible inventory to match:

```bash
# Edit ansible/inventory.yml
nano ansible/inventory.yml
```

Update the workers section to match your new worker count. For example, for 5 workers:
```yaml
workers:
  hosts:
    k3s-worker-1:
      ansible_host: 192.168.1.185
    k3s-worker-2:
      ansible_host: 192.168.1.186
    k3s-worker-3:
      ansible_host: 192.168.1.187
    k3s-worker-4:
      ansible_host: 192.168.1.188
    k3s-worker-5:
      ansible_host: 192.168.1.189
```

### Change IP Addresses

Edit `terraform/terraform.tfvars`:

```hcl
control_plane_ip_start = "192.168.1.190"
worker_ip_start = "192.168.1.195"
```

### Change K3s Version

Edit `terraform/terraform.tfvars`:

```hcl
k3s_version = "v1.34.1+k3s1"  # Current default, change to any valid K3s version
```

## Useful Commands

### Terraform

```bash
# Show current state
terraform show

# List resources
terraform state list

# Destroy everything
terraform destroy

# Show outputs
terraform output

# Get specific output
terraform output -raw k3s_token
terraform output -json control_plane_ips
```

### Kubectl

```bash
# Set context
export KUBECONFIG=$(pwd)/kubeconfig

# Get cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Deploy test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc
```

### Ansible

```bash
# Test connectivity
ansible -i ansible/inventory.yml all -m ping

# Run specific playbook
ansible-playbook -i ansible/inventory.yml ansible/k3s-install.yml
ansible-playbook -i ansible/inventory.yml ansible/system-utils-install.yml
ansible-playbook -i ansible/inventory.yml ansible/argocd-install.yml

# Check K3s status
ansible -i ansible/inventory.yml control_plane -a "kubectl get nodes" -b
```

## ArgoCD Installation

### What is ArgoCD?
ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of applications to your Kubernetes cluster by syncing with Git repositories.

### Features
- **GitOps Workflow**: Automatically syncs applications from Git repositories
- **Web UI**: Visual interface for managing applications
- **Declarative**: Define your desired state in Git
- **Multi-cluster**: Can manage multiple Kubernetes clusters
- **Rollback**: Easy rollback to previous versions

### Installation Options
1. **During deployment**: Choose "yes" when prompted during `./deploy.sh`
2. **Manual installation**: Run `ansible-playbook -i ansible/inventory.yml ansible/argocd-install.yml`

### Accessing ArgoCD
```bash
# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Troubleshooting

### Network Device Configuration

If worker nodes are not getting IP addresses, ensure all VMs use network device ID 0:

```bash
# Check network configuration in main.tf
grep -A 3 "network {" main.tf
```

All VMs should have `network { id = 0 }` to ensure CloudInit properly configures network interfaces.

### VMs Not Booting

```bash
# Check VM status in Proxmox
ssh root@192.168.1.200 "qm list"

# Check specific VM
ssh root@192.168.1.200 "qm status <VMID>"

# View console
# Access Proxmox web UI: https://192.168.1.200:8006
```

### SSH Connection Issues

```bash
# Test SSH manually
ssh -v ubuntu@192.168.1.180

# Check cloud-init logs on VM
ssh ubuntu@192.168.1.180 "sudo cloud-init status --long"

# Verify SSH key
cat ~/.ssh/id_ed25519.pub
```

### K3s Installation Fails

```bash
# Check K3s service status
ssh ubuntu@192.168.1.180 "sudo systemctl status k3s"

# View K3s logs
ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -f"

# Reinstall K3s manually
ssh ubuntu@192.168.1.180
curl -sfL https://get.k3s.io | sh -
```

### Terraform State Issues

```bash
# Refresh state
terraform refresh

# Import existing VM
terraform import proxmox_vm_qemu.k3s_control_plane[0] proxmox/<VMID>

# Remove from state (doesn't delete VM)
terraform state rm proxmox_vm_qemu.k3s_worker[0]
```

### Provider Compatibility

This project uses telmate/proxmox provider v3.0.2-rc05 which has breaking changes from v2.x:

- Use `cpu` block instead of `cpu` argument
- Network blocks require explicit `id` field
- CloudInit requires explicit `ide2 cloudinit` drive
- Serial port requires explicit configuration

## Destroying the Cluster

### Option 1: Terraform Destroy (Recommended)

```bash
# Destroy all resources
terraform destroy

# Auto-approve (skip confirmation)
terraform destroy -auto-approve
```

### Option 2: Manual Cleanup

```bash
# Stop and remove VMs
ssh root@192.168.1.200
qm stop <VMID>
qm destroy <VMID>
```

## Security Considerations

1. **Change default password**: The VMs use `ubuntu:ubuntu` by default
   ```bash
   ssh ubuntu@192.168.1.180 "sudo passwd ubuntu"
   ```

2. **Disable password auth**: Use SSH keys only
   ```bash
   ssh ubuntu@192.168.1.180 "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl reload sshd"
   ```

3. **Firewall**: Configure UFW on nodes
   ```bash
   ssh ubuntu@192.168.1.180 "sudo ufw allow 22/tcp && sudo ufw allow 6443/tcp && sudo ufw --force enable"
   ```

4. **API Token**: Keep your Proxmox API token secret secure
   - Never commit `terraform.tfvars` to git
   - Use `.gitignore` to exclude sensitive files

## Next Steps

After deployment, you can:

1. **Access ArgoCD** (if installed): Set up GitOps workflows for your applications
2. **Install a CNI plugin** (if not using default Flannel)
3. **Deploy cert-manager** for TLS certificates
4. **Install Helm** for package management
5. **Traefik Ingress Controller** (enabled by default)
6. **Configure persistent storage** (Longhorn, NFS)
7. **Setup monitoring** (Prometheus, Grafana)
8. **Deploy applications** using ArgoCD or kubectl

### Using ArgoCD for Application Deployment
Once ArgoCD is installed, you can:
- Create Application manifests in Git
- Connect ArgoCD to your Git repositories
- Automatically deploy and sync applications
- Monitor application health through the UI
- Rollback to previous versions if needed

### Traefik Ingress Controller
Traefik is now enabled by default in K3s and provides:
- Built-in ingress controller for routing HTTP/HTTPS traffic
- Automatic SSL certificate management
- Load balancing capabilities
- Service discovery

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)

## License

MIT

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review Terraform/Ansible logs
3. Check Proxmox VE logs
4. Consult K3s documentation