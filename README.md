# vCluster Autonodes Proxmox

This repository contains Terraform configurations for automatically provisioning virtual machines in Proxmox for use with vCluster. The setup allows for dynamic node creation and management in a Proxmox environment.

## Prerequisites

- Proxmox Virtual Environment
- Terraform installed
- SSH agent running (for authentication)
- Ubuntu cloud image (noble-server-cloudimg-amd64.img) uploaded to Proxmox
- Snippets enabled on the Proxmox datastore

## Provider Configuration

The configuration uses the `bpg/proxmox` Terraform provider version 0.85.1. The provider is configured to connect to a Proxmox instance with the following settings:

```hcl
provider "proxmox" {
  endpoint = "https://192.168.86.5:8006/"
  insecure = true
  ssh {
    agent = true
  }
}
```

**Note:** The `insecure = true` setting is used for environments with self-signed certificates. In production environments, proper SSL certificates should be configured.

## Features

1. **Dynamic VM Naming**: Uses a random string generator to create unique VM names
2. **Cloud-Init Integration**: Automatically configures VMs using cloud-init
3. **Flexible Resource Allocation**: CPU and memory resources are configurable through vCluster nodeType specifications
4. **Network Configuration**: DHCP-based networking by default
5. **Storage Configuration**: Uses local-lvm datastore for VM storage

## VM Configuration

### Cloud-Init Setup
- Automatically sets hostname based on vCluster nodeClaim metadata
- Configures ubuntu user (for testing purposes)
- Supports custom user data injection

### Hardware Resources
- CPU cores are configurable through vCluster nodeType
- Memory is specified in megabytes
- Default disk size: 120GB
- Network: Configured to use bridge vmbr0

### Storage Configuration
- System disk: Uses Ubuntu cloud image (noble-server)
- Datastore: local-lvm
- Supports disk features:
  - IOThread enabled
  - Discard enabled
  - Virtio interface

## Security Considerations

1. The default configuration includes a test user (ubuntu) with password authentication enabled. For production:
   - Disable password authentication
   - Use SSH keys instead
   - Remove the default user configuration
2. The provider is configured to accept insecure SSL certificates. In production:
   - Use valid SSL certificates
   - Remove the `insecure = true` setting

## Usage with vCluster

This configuration is designed to work with vCluster Platform, where:
- Node types are defined in vCluster Platform
- Resource specifications (CPU, memory) are pulled from vCluster variables
- Node naming follows vCluster conventions

## Notes

- The configuration assumes Proxmox node name "pve2" - adjust as needed
- Cloud-init snippets must be enabled on the local datastore
- The Ubuntu cloud image must be pre-loaded in the Proxmox environment
- Default network configuration uses DHCP, but can be modified for static IP addressing if required
