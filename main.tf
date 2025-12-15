provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

resource "proxmox_virtual_environment_container" "open-webui-container" {
  node_name = var.proxmox_node

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "open-webui"

    user_account {
      password = var.proxmox_host_default_pwd
    }

    ip_config {
      ipv4 {
        address = "${var.static_ips.open_webui}/32" #fixed IP address
        #address = "dhcp"
        gateway = "192.168.86.1"
      }
    }
  }

  network_interface {
    name = "eth0"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian13-docker-template.tar.gz"
    type             = "debian"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get uograde -y",
      "docker run -d -p 80:8080 -e OLLAMA_BASE_URL=${var.ollama_host} -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main"
    ]
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true #needs the agent up and running and have the key loaded
    }
  }

}

resource "proxmox_virtual_environment_container" "n8n-container" {
  node_name = var.proxmox_node

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "n8n"

    user_account {
      password = var.proxmox_host_default_pwd
    }

    ip_config {
      ipv4 {
        address = "${var.static_ips.n8n}/32"
        #address = "dhcp"
        gateway = "192.168.86.1"
      }
    }
  }

  network_interface {
    name = "eth0"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian13-docker-template.tar.gz"
    type             = "debian"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 50
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 6144
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "docker volume create n8n_data",
      "docker run -d -it --rm --name n8n -p 5678:5678 -e GENERIC_TIMEZONE='America/New_York' -e TZ='America/New_York' -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true -e N8N_RUNNERS_ENABLED=true -e N8N_SECURE_COOKIE=false -e DB_SQLITE_POOL_SIZE=5 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n"
    ]
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true
    }
  }
}
