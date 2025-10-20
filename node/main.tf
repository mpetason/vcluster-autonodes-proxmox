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
  
  ssh {
    agent = true
  }
}

locals {
  domain = "vcluster-demo.local"
}

resource "random_id" "vm_suffix" {
  byte_length = 4
}

resource "proxmox_virtual_environment_vm" "ubuntu_vms" {

  name      = local.vm_name
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