output "k3s_token" {
  description = "K3s cluster token"
  value       = local.k3s_token
  sensitive   = true
}

output "control_plane_ips" {
  description = "Control plane node IP addresses"
  value = [
    for i in range(var.control_plane_count) :
    cidrhost("192.168.1.0/24", 180 + i)
  ]
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = [
    for i in range(var.worker_count) :
    cidrhost("192.168.1.0/24", 185 + i)
  ]
}

output "control_plane_names" {
  description = "Control plane node names"
  value       = [for vm in proxmox_vm_qemu.k3s_control_plane : vm.name]
}

output "worker_names" {
  description = "Worker node names"
  value       = [for vm in proxmox_vm_qemu.k3s_worker : vm.name]
}

output "ssh_command_control_plane" {
  description = "SSH command for control plane node"
  value       = "ssh ubuntu@${cidrhost("192.168.1.0/24", 180)}"
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig from control plane"
  value       = "ssh ubuntu@${cidrhost("192.168.1.0/24", 180)} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}

output "cluster_info" {
  description = "K3s cluster information"
  value = {
    control_plane = {
      count  = var.control_plane_count
      cpu    = var.control_plane_cpu
      memory = var.control_plane_memory
      ips    = [for i in range(var.control_plane_count) : cidrhost("192.168.1.0/24", 180 + i)]
    }
    workers = {
      count  = var.worker_count
      cpu    = var.worker_cpu
      memory = var.worker_memory
      ips    = [for i in range(var.worker_count) : cidrhost("192.168.1.0/24", 185 + i)]
    }
    k3s_version = var.k3s_version
  }
}