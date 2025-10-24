terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.86.5:8006/"
  insecure = true
  ssh {
    agent = true
  }
}

resource "random_string" "vm_name_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric  = true
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve2"


  source_raw {
    data = <<-EOT
      #cloud-config
      hostname: "vcluster-${var.vcluster.nodeClaim.metadata.name}"
      chpasswd:
        expire: false
        users:
        - {name: ubuntu, password: ubuntu, type: text}
      ssh_pwauth: true

      ${replace(var.vcluster.userData, "#cloud-config", "")}
    EOT

    file_name = "${random_string.vm_name_suffix.result}-user-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vms" {
  
  name      = "vcluster-${var.vcluster.nodeClaim.metadata.name}-${random_string.vm_name_suffix.result}"
  node_name = "pve2"

  initialization {
    
    user_data_file_id = user_data_file_name = proxmox_virtual_environment_file.user_data_cloud_config.file_name
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
  cpu {
    cores = var.vcluster.nodeType.spec.resources.cpu
    type = "host"
  }
  memory {
    dedicated = trim(var.vcluster.nodeType.spec.resources.memory, "M")
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 120
  }

  network_device {
    bridge = "vmbr0"
  }
}