output "ansible_inventory_lxc" {
  value = templatefile("${path.module}/ansible/inventory.tpl", {
    containers = {
      "n8n"        = proxmox_virtual_environment_container.n8n-container.ipv4["eth0"]
      "open-webui" = proxmox_virtual_environment_container.open-webui-container.ipv4["eth0"]
      "searxng"    = proxmox_virtual_environment_container.searxng-container.ipv4["eth0"]
    }
  })
}
