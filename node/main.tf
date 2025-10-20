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
  number  = true
}

locals {
  domain = "vcluster-demo.local"
}

resource "proxmox_virtual_environment_vm" "ubuntu_vms" {

  name      = "my-vm-${random_string.vm_name_suffix.result}"
  node_name = "pve"

  initialization {

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