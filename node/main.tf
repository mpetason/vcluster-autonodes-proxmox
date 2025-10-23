terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.86.9:8006/"
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
  node_name    = "pve"


  source_raw {
    data = <<-EOT
      #cloud-config
      hostname: ${var.vcluster.nodeClaim.metadata.name}
      manage_etc_hosts: true
      ssh_pwauth: true

      ${replace(var.vcluster.userData, "#cloud-config", "")}
    EOT

    file_name = "user-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vms" {

  name      = "my-vm-${random_string.vm_name_suffix.result}"
  node_name = "pve"

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
    user_account {
      username = "ubuntu"
      # Replace this with SSH Key
      password = "ubuntu"
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
  cpu {
    cores = 2
    sockets = 1
    type = "host"
  }
  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 200
  }

  network_device {
    bridge = "vmbr0"
  }
}