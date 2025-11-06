terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc05"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

# Generate random token for K3s cluster
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

locals {
  k3s_token = var.k3s_token != "" ? var.k3s_token : random_password.k3s_token.result
}

# Control Plane Nodes
resource "proxmox_vm_qemu" "k3s_control_plane" {
  count = var.control_plane_count

  name        = "k3s-cp-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_id
  full_clone  = true
  vmid        = var.vm_id_start + count.index
  
  agent    = 1
  os_type  = "cloud-init"
  memory   = var.control_plane_memory
  
  cpu {
    type    = "host"
    cores   = var.control_plane_cpu
    sockets = 1
  }
  scsihw   = "virtio-scsi-single"
  bootdisk = "scsi0"
  
  onboot  = true
  startup = "order=1"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = var.control_plane_disk_size
        }
      }
    }
    # CloudInit drive
    ide {
      ide2 {
        cloudinit {
          storage = var.snippet_storage
        }
      }
    }
  }

  network {
    id     = count.index
    model  = "virtio"
    bridge = var.bridge
  }

  # Serial port for console access
  serial {
    id = 0
    type = "socket"
  }

  ipconfig0 = "ip=${cidrhost("192.168.1.0/24", 180 + count.index)}/24,gw=${var.gateway}"
  
  nameserver    = var.nameserver
  searchdomain  = var.searchdomain
  
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = var.ssh_public_key

  lifecycle {
    ignore_changes = [
      network,
      ciuser,
      sshkeys,
    ]
  }
}

# Worker Nodes
resource "proxmox_vm_qemu" "k3s_worker" {
  count = var.worker_count

  name        = "k3s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_id
  full_clone  = true
  vmid        = var.vm_id_start + var.control_plane_count + count.index
  
  agent    = 1
  os_type  = "cloud-init"
  memory   = var.worker_memory
  
  cpu {
    type    = "host"
    cores   = var.worker_cpu
    sockets = 1
  }
  scsihw   = "virtio-scsi-single"
  bootdisk = "scsi0"
  
  onboot  = true
  startup = "order=2"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = var.worker_disk_size
        }
      }
    }
    # CloudInit drive
    ide {
      ide2 {
        cloudinit {
          storage = var.snippet_storage
        }
      }
    }
  }

  network {
    id     = count.index
    model  = "virtio"
    bridge = var.bridge
  }

  # Serial port for console access
  serial {
    id = 0
    type = "socket"
  }

  ipconfig0 = "ip=${cidrhost("192.168.1.0/24", 185 + count.index)}/24,gw=${var.gateway}"
  
  nameserver    = var.nameserver
  searchdomain  = var.searchdomain
  
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = var.ssh_public_key

  lifecycle {
    ignore_changes = [
      network,
      ciuser,
      sshkeys,
    ]
  }

  depends_on = [proxmox_vm_qemu.k3s_control_plane]
}