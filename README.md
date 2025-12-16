# Proxmox Terraform Configuration

This repository contains Terraform configuration for deploying containerized applications on Proxmox using LXC containers.

## What This Deploys

This configuration creates two Docker-enabled LXC containers:

1. **Open WebUI** (`open-webui-container`) - Web interface for Ollama AI models
   - 1 CPU core, 1GB RAM, 10GB storage
   - Runs on static IP with gateway routing
   - Automatically deploys Open WebUI Docker container
   - Uses Ollama from a remote machine

2. **n8n** (`n8n-container`) - Workflow automation platform
   - 2 CPU cores, 6GB RAM, 50GB storage
   - Runs on static IP with gateway routing
   - Automatically deploys n8n Docker container with persistence and SQLLite

## Prerequisites

- Terraform >= 1.0
- Proxmox VE server with API access
- **Custom Debian 13 Docker template** (`debian13-docker-template.tar.gz`) available in Proxmox local storage:
   -- with **docker** installed and running and
   -- with an **SSH key** for remote provisioning
- Proxmox user/API token with appropriate permissions (see below)
- SSH key loaded in ssh-agent for remote provisioning

## Setup

### 1. Configure Proxmox API Token

Create a dedicated API token in Proxmox with required permissions:

```bash
# Create user and API token
pveum user add terraform@pve
pveum user token add terraform@pve terraform-token --privsep=0

# Grant necessary permissions
pveum role add TerraformRole -privs "VM.Allocate VM.Config.Disk VM.Config.Memory VM.Config.CPU VM.Config.Network VM.Config.Options Datastore.AllocateSpace Datastore.Audit Sys.Modify Sys.Audit"
pveum acl modify / --user terraform@pve --role TerraformRole

# Or use PVEAdmin for simpler setup
pveum acl modify / --user terraform@pve --role PVEAdmin
```

**Note**: You need at minimum `Sys.Modify` permission to avoid HTTP 403 errors when creating containers.

### 2. Prepare the Container Template

1. Create a template based of a running LXC container with docker installed and your ssh-key provisioned for the root user.
2. Stop the container.
3. Remove the network interface.
4. `vzdump 100 --mode stop --compress gzip --dumpdir /var/lib/vz/template/cache`, replace `100` with the LXC conatiner id. 
5. `cd /var/lib/vz/template/cache` and search for the tar.gz file with the time and the date of the execution of the `vzdump` command.
6. Rename the file to `debian13-docker-template.tar.gz`
7. Refresh the ui and you should see the `debian13-docker-template.tar.gz` under Datacenter -> your Node -> local (your node) -> CT Templates. Or verify template exists via terminal

```bash
# Verify template exists in Proxmox
ls -la /var/lib/vz/template/cache/debian13-docker-template.tar.gz
```

### 3. Configure Variables

Create a `terraform.tfvars` file with your configuration:

```hcl
proxmox_api_url        = "https://your-proxmox-server:8006/api2/json"
proxmox_api_token      = "terraform@pve!terraform-token=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
proxmox_tls_insecure   = true  # Set to false if using valid SSL certificate
proxmox_node           = "pve"  # Your Proxmox node name
proxmox_host_default_pwd = "your-secure-root-password"

static_ips = {
  open_webui = "192.168.1.100"  # Adjust to your network
  n8n        = "192.168.1.101"
}
```

### 4. Set Up SSH Agent

The provisioners use SSH to configure containers. Ensure your SSH agent is running:

```bash
# Start ssh-agent if not running
eval $(ssh-agent)

# Add your SSH key
ssh-add ~/.ssh/id_rsa
```

### 5. Set up Environment Variables
User Environment variables for 
```bash
TF_VAR_proxmox_api_token
TF_VAR_proxmox_host_default_pwd
```
One way to set these variables on a Mac is by following [Securing Proxmox API Tokens with Apple Keychain](https://blog.renewelches.com/2025/12/09/proxmox-terraform-keychain/).

### 6. Initialize Terraform

```bash
terraform init
```

### 7. Deploy Infrastructure

```bash
# Preview changes
terraform plan

# Apply configuration
terraform apply
```

The containers will be created and the Docker containers will be automatically deployed via SSH provisioners.

## Security Best Practices

1. **Never commit `terraform.tfvars`** - Add it to `.gitignore`
2. **Use environment variables** for sensitive data:

   ```bash
   export TF_VAR_proxmox_api_token="terraform@pve!token=xxxxx"
   export TF_VAR_proxmox_host_default_pwd="your-password"
   ```

3. **Use API tokens** instead of user passwords (recommended)
4. **Use SSH keys** instead of password authentication
5. **Enable state encryption** if using remote backends
6. **Restrict Terraform user permissions** to minimum required (see permission setup above)

## File Structure

```bash
.
├── README.md                    # This file
├── versions.tf                  # Provider version constraints (using bpg/proxmox provider)
├── variables.tf                 # Variable definitions
├── main.tf                      # Main configuration (2 LXC containers with Docker)
└── terraform.tfvars             # Your configuration (git-ignored)
```

## Resources Deployed

The [main.tf](main.tf) file contains two LXC container resources:

1. **open-webui-container** - Deploys [Open WebUI](https://github.com/open-webui/open-webui) connected to Ollama
   - Accessible at `http://<static_ip>:80`
   - Connected to Ollama at `http://<your ollam URL>:11434`

2. **n8n-container** - Deploys [n8n](https://n8n.io) workflow automation
   - Accessible at `http://<static_ip>:5678`
   - Configured for America/New_York timezone
   - Persistent data storage with Docker volumes

## Troubleshooting

### Permission Denied (HTTP 403)

If you see `Permission check failed (/, Sys.Modify)`:

```bash
# Grant Sys.Modify permission
pveum acl modify / --user terraform@pve --role PVEAdmin
```

See the permission setup section above for complete instructions.

### TLS Certificate Issues

If using self-signed certificates, set in your `terraform.tfvars`:

```hcl
proxmox_tls_insecure = true
```

### SSH Connection Issues

Ensure your SSH key is loaded:

```bash
ssh-add -l  # List loaded keys
ssh-add ~/.ssh/id_rsa  # Add if not loaded
```

### Container Template Not Found

Verify the template exists in Proxmox storage:

```bash
ls -la /var/lib/vz/template/cache/debian13-docker-template.tar.gz
```

## Known Issues

- Container provisioning requires working ssh-agent with loaded keys
- Static IPs must be in the same subnet as the gateway

## Additional Resources

- [bpg/proxmox Provider Documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Open WebUI Documentation](https://docs.openwebui.com/)
- [n8n Documentation](https://docs.n8n.io/)
