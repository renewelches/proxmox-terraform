# Proxmox Terraform Configuration

This repository contains Terraform configuration for managing Proxmox resources.

## Prerequisites

- Terraform >= 1.0
- Access to a Proxmox server
- Proxmox user with appropriate API permissions

## Setup

### 1. Configure Proxmox User

Create a dedicated Terraform user in Proxmox with appropriate permissions:

```bash
pveum user add terraform@pve
pveum passwd terraform@pve
pveum aclmod / -user terraform@pve -role PVEAdmin
```

### 2. Configure Variables

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update the values for your environment.

### 3. Set Password Securely

**Best Practice**: Use environment variables instead of storing passwords in files.

```bash
export TF_VAR_proxmox_password="your-secure-password"
```

Alternatively, you can use:
- **Terraform Cloud/Enterprise**: Store as sensitive variables
- **HashiCorp Vault**: Integrate with Vault provider
- **AWS Secrets Manager/Azure Key Vault**: Use cloud secret management

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan and Apply

```bash
terraform plan
terraform apply
```

## Security Best Practices

1. **Never commit `terraform.tfvars`** - It's in `.gitignore` by default
2. **Use environment variables** for sensitive data:
   ```bash
   export TF_VAR_proxmox_password="password"
   export TF_VAR_proxmox_api_url="https://proxmox:8006/api2/json"
   ```
3. **Use API tokens** instead of passwords (Proxmox 6.2+):
   ```hcl
   pm_api_token_id     = "terraform@pve!mytoken"
   pm_api_token_secret = "your-token-secret"
   ```
4. **Enable state encryption** if using remote backends
5. **Restrict Terraform user permissions** to minimum required

## File Structure

```
.
├── README.md                    # This file
├── versions.tf                  # Provider version constraints
├── variables.tf                 # Variable definitions
├── main.tf                      # Main configuration
├── terraform.tfvars.example     # Example variables file
└── .gitignore                   # Git ignore rules
```

## Example Resources

The `main.tf` file contains commented examples for creating VMs. Uncomment and modify as needed for your infrastructure.

## Useful Commands

```bash
# Initialize and download providers
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show current state
terraform show
```

## Troubleshooting

### TLS Certificate Issues

If using self-signed certificates, set:
```hcl
proxmox_tls_insecure = true
```

### Authentication Issues

Ensure your user has proper permissions in Proxmox:
```bash
pveum user list
pveum aclmod / -user terraform@pve -role PVEAdmin
```

## Additional Resources

- [Telmate Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
