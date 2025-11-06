# K3s on Proxmox - Complete Deployment Guide

## 📋 Overview

This guide will walk you through deploying a production-ready K3s Kubernetes cluster on Proxmox VE using Terraform and Ansible.

**What you'll get:**
- 1 Control Plane node (4 vCPU, 8GB RAM)
- 3 Worker nodes (2 vCPU, 4GB RAM each)
- Fully configured K3s cluster
- Kubeconfig for local access
- Automated deployment

---

## 🚀 Step-by-Step Deployment

### Step 1: Create Project Directory in WSL

Open your WSL terminal in VS Code and run:

```bash
cd ~
mkdir -p k3s-proxmox-terraform
cd k3s-proxmox-terraform
```

### Step 2: Create All Configuration Files

Copy each of the provided files into your project directory:

1. **main.tf** - Main Terraform configuration
2. **variables.tf** - Variable definitions
3. **outputs.tf** - Output definitions
4. **terraform.tfvars.example** - Example variables
5. **.gitignore** - Git ignore file
6. **README.md** - Documentation
7. **deploy.sh** - Automated deployment script
8. **setup.sh** - Setup script
9. **ansible/inventory.yml** - Ansible inventory
10. **ansible/k3s-install.yml** - K3s installation playbook

**Quick way using VS Code:**
1. Create files in VS Code with the exact names above
2. Copy the content from each artifact I provided
3. Save all files

**Or use command line:**

```bash
# Create ansible directory
mkdir -p ansible

# Create empty files
touch main.tf variables.tf outputs.tf terraform.tfvars.example
touch deploy.sh setup.sh README.md .gitignore
touch ansible/inventory.yml ansible/k3s-install.yml

# Then edit each file and paste the content
```

### Step 3: Configure Your Variables

```bash
# Copy example to actual file
cp terraform.tfvars.example terraform.tfvars

# Edit with your token secret
nano terraform.tfvars
```

**IMPORTANT:** Replace `YOUR_TOKEN_SECRET_HERE` with your actual Proxmox API token secret!

```hcl
proxmox_api_token_secret = "your-actual-secret-here"
```

Save and exit (Ctrl+X, Y, Enter in nano)

### Step 4: Make Scripts Executable

```bash
chmod +x setup.sh deploy.sh
```

### Step 5: Run Setup Check

```bash
./setup.sh
```

This will:
- Create necessary directories
- Check prerequisites (Terraform, Ansible, jq)
- Install missing dependencies
- Verify Proxmox connectivity
- Verify SSH key exists

### Step 6: Review Configuration

```bash
# View your configuration
cat terraform.tfvars

# Ensure token secret is filled in
grep "proxmox_api_token_secret" terraform.tfvars
```

### Step 7: Deploy the Cluster! 🎉

```bash
./deploy.sh
```

The script will:
1. Initialize Terraform ⏳
2. Validate configuration ✓
3. Show deployment plan 📋
4. Ask for confirmation ❓
5. Create 4 VMs on Proxmox 🖥️
6. Wait for VMs to boot ⏱️
7. Install K3s cluster 🚀
8. Save kubeconfig locally 📝

**Expected duration:** 5-10 minutes

### Step 8: Access Your Cluster

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Verify cluster
kubectl get nodes

# Expected output:
# NAME           STATUS   ROLES                  AGE   VERSION
# k3s-cp-1       Ready    control-plane,master   2m    v1.31.3+k3s1
# k3s-worker-1   Ready    <none>                 1m    v1.31.3+k3s1
# k3s-worker-2   Ready    <none>                 1m    v1.31.3+k3s1
# k3s-worker-3   Ready    <none>                 1m    v1.31.3+k3s1

# Check all pods
kubectl get pods -A
```

---

## 🔍 Manual Deployment (Alternative)

If you prefer step-by-step control:

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
```

### 3. Preview Changes

```bash
terraform plan
```

Review the plan carefully to ensure everything looks correct.

### 4. Create VMs

```bash
terraform apply
```

Type `yes` when prompted.

### 5. Wait for VMs

```bash
# Wait for VMs to boot (about 60 seconds)
sleep 60

# Test SSH to control plane
ssh ubuntu@192.168.1.180 "echo 'SSH working'"
```

### 6. Get K3s Token

```bash
export K3S_TOKEN=$(terraform output -raw k3s_token)
echo "K3s Token: $K3S_TOKEN"
```

### 7. Install K3s with Ansible

```bash
cd ansible
ansible-playbook -i inventory.yml k3s-install.yml
cd ..
```

### 8. Configure Local Access

```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

---

## 🧪 Testing Your Cluster

### Deploy a Test Application

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx

# Expose as NodePort service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get the NodePort
kubectl get svc nginx

# Access from your browser
# http://192.168.1.185:<NodePort>
```

### Check Cluster Health

```bash
# Node status
kubectl get nodes -o wide

# All pods
kubectl get pods -A

# Cluster info
kubectl cluster-info

# System components
kubectl get pods -n kube-system
```

---

## 🛠️ Common Operations

### SSH to Nodes

```bash
# Control plane
ssh ubuntu@192.168.1.180

# Workers
ssh ubuntu@192.168.1.185
ssh ubuntu@192.168.1.186
ssh ubuntu@192.168.1.187
```

### View K3s Logs

```bash
# On control plane
ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -f"

# On worker
ssh ubuntu@192.168.1.185 "sudo journalctl -u k3s-agent -f"
```

### Check K3s Status

```bash
ssh ubuntu@192.168.1.180 "sudo systemctl status k3s"
```

### Get Cluster Token

```bash
terraform output -raw k3s_token
```

### Update Kubeconfig

If you need to regenerate kubeconfig:

```bash
ssh ubuntu@192.168.1.180 "sudo cat /etc/rancher/k3s/k3s.yaml" | \
  sed 's/127.0.0.1/192.168.1.180/' > kubeconfig
chmod 600 kubeconfig
```

---

## 🔧 Troubleshooting

### Issue: VMs not starting

**Check VM status:**
```bash
ssh root@192.168.1.200 "qm list"
```

**Check specific VM:**
```bash
ssh root@192.168.1.200 "qm status 100"  # Replace 100 with your VMID
```

**Solution:** Access Proxmox web UI and check console

---

### Issue: Cannot SSH to VMs

**Test connectivity:**
```bash
ping 192.168.1.180
```

**Check cloud-init status:**
```bash
ssh ubuntu@192.168.1.180 "sudo cloud-init status"
```

**Solution:** 
- Ensure VM has fully booted (wait 2-3 minutes)
- Check that SSH key is correct in terraform.tfvars
- Verify network configuration

---

### Issue: Terraform can't connect to Proxmox

**Test API:**
```bash
curl -k https://192.168.1.200:8006/api2/json/version
```

**Solution:**
- Verify API token secret is correct
- Check Proxmox API is accessible
- Ensure token has correct permissions

---

### Issue: K3s installation fails

**Check logs:**
```bash
ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -n 100"
```

**Manual installation:**
```bash
ssh ubuntu@192.168.1.180
curl -sfL https://get.k3s.io | sh -
sudo systemctl status k3s
```

---

### Issue: Nodes not joining cluster

**Check worker logs:**
```bash
ssh ubuntu@192.168.1.185 "sudo journalctl -u k3s-agent -n 100"
```

**Verify connectivity:**
```bash
ssh ubuntu@192.168.1.185 "curl -k https://192.168.1.180:6443"
```

**Solution:** Ensure control plane is fully ready before workers join

---

## 🗑️ Cleanup / Destroy

### Option 1: Terraform Destroy (Recommended)

```bash
# Destroy all resources
terraform destroy

# Or with auto-approve
terraform destroy -auto-approve
```

### Option 2: Manual Cleanup

```bash
# Connect to Proxmox
ssh root@192.168.1.200

# List VMs
qm list | grep k3s

# Stop and destroy each VM
qm stop <VMID>
qm destroy <VMID>
```

---

## 📝 Post-Deployment Tasks

### 1. Change Default Password

```bash
# SSH to each node and change password
ssh ubuntu@192.168.1.180 "sudo passwd ubuntu"
```

### 2. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 3. Install Cert-Manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 4. Install Longhorn (Storage)

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

### 5. Install Nginx Ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

---

## 🎯 Next Steps

1. **Learn kubectl basics**: [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
2. **Deploy your first app**: Follow the test application example above
3. **Setup monitoring**: Install Prometheus and Grafana
4. **Configure backups**: Setup Velero for cluster backups
5. **Secure your cluster**: Implement Network Policies and RBAC

---

## 📚 Useful Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Documentation](https://helm.sh/docs/)
- [Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)

---

## ✅ Deployment Checklist

- [ ] All files created in project directory
- [ ] terraform.tfvars configured with API token secret
- [ ] Scripts made executable (chmod +x)
- [ ] Prerequisites installed (Terraform, Ansible, jq)
- [ ] SSH key exists and is correct
- [ ] Proxmox is accessible
- [ ] Template 9100 exists on Proxmox
- [ ] IP range 192.168.1.180-187 is available
- [ ] Sufficient resources (10 vCPU, 20GB RAM)
- [ ] ./deploy.sh executed successfully
- [ ] kubectl get nodes shows all nodes Ready
- [ ] Test application deployed and working

---

**Congratulations! You now have a fully functional K3s cluster! 🎉**