# This example uses the bpg/proxmox provider
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
  }
}

# When using enviroment variables we need to set the endopint. We
# also need to set insecure to true if we are not using a valid certificate.
# When using the variables option we should be able to define it in a secret
# in Kubernetes. (updating with the next vCluster release.)
provider "proxmox" {
  endpoint = "https://192.168.86.5:8006/"
  insecure = true
  ssh {
    agent = true
  }
}

# This gives us a random value for our VM and hostname
resource "random_string" "vm_name_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric  = true
}

# We need to create a cloud-config file to hold our UserData. Snippets 
# need to be enabled on the datastore.
resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve2"

  # We are going to set the hostname of the VM here, this will be used 
  # as the node name when it is checked in. Also, for testing we enable the
  # ubuntu user with ubuntu as the password so we can ssh/console. In production
  # this should be disabledc and you would use an ssh-key.
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

    # We give the filename a custom name so that we don't re-use the same file with the same
    # hostname. If it has the same hostname then it will join the node but it will run into issues
    # because the node name was already used.
    file_name = "${var.vcluster.nodeClaim.metadata.name}-user-data-cloud-config.yaml"
  }
}

# Here we create the VM with vcluster- and the values we defined earlier.
resource "proxmox_virtual_environment_vm" "ubuntu_vms" {
  
  name      = "vcluster-${var.vcluster.nodeClaim.metadata.name}-${random_string.vm_name_suffix.result}"
  node_name = "pve2"

  initialization {

    # We tell the VM where the userdata is. It is using the ID of the file created above.
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id

    # for this demo we just use DHCP, but you could configure static IP addresses if needed.
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # We want to use the CPU/Memory defined in the nodeType, so we use the vCluster variable to set this.
  # The nodetypes will be created in vCluster Platform when we create the provider.
  cpu {
    cores = var.vcluster.nodeType.spec.resources.cpu
    type = "host"
  }
  memory {
    dedicated = trim(var.vcluster.nodeType.spec.resources.memory, "M")
  }

  # This is where we specify the disk size and the cloud image to use. In this
  # example we downloaded the noble-server image and uploaded it to the local datastore.
  # The VM itself will be installed on the local-lvm datastore.
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