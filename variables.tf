variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token, use environment variable or secure vault (e.g. terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (set to true for self-signed certificates)"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Target Proxmox node name"
  type        = string
}


variable "proxmox_host_default_pwd" {
  description = "The root user password for the host"
  type        = string
  sensitive   = true
}

variable "static_ips" {
  description = "Map of static IP addresses for resources"
  type        = map(string)
}
