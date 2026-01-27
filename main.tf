provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

# Generate the docker.env file from template, injecting the SearXNG URL
# This allows the SEARXNG_QUERY_URL to be dynamically set based on var.static_ips.searxng
resource "local_file" "openwebui_env" {
  content = templatefile("${path.module}/openwebui/docker.env.tpl", {
    searxng_query_url = "http://${var.static_ips.searxng}/search?q=<query>"
  })
  filename = "${path.module}/openwebui/docker.env.rendered"
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
    size         = 20
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1536
  }

  # Copy the rendered docker.env file (generated from template with Terraform variables)
  # Depends on local_file.openwebui_env to ensure the file is generated first
  provisioner "file" {
    source      = local_file.openwebui_env.filename
    destination = "/tmp/docker.env"
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true #needs the agent up and running and have the key loaded
    }
  }
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "docker run -d --restart unless-stopped -p 80:8080 -e OLLAMA_BASE_URL=${var.ollama_host} --env-file /tmp/docker.env -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main"
    ]
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true #needs the agent up and running and have the key loaded
    }
  }

}

resource "proxmox_virtual_environment_container" "searxng-container" {
  node_name = var.proxmox_node

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "searxng"

    user_account {
      password = var.proxmox_host_default_pwd
    }

    ip_config {
      ipv4 {
        address = "${var.static_ips.searxng}/32"
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
    cores = 1
  }

  memory {
    dedicated = 1024
  }
  provisioner "file" {
    source      = "searxng/settings.yml"
    destination = "/tmp/settings.yml"
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true #needs the agent up and running and have the key loaded
    }
  }
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "mkdir ./config",
      "mv /tmp/settings.yml ./config/",
      # "docker run -d --dns=9.9.9.9 --restart unless-stopped -p 80:8080  -v ./config/:/etc/searxng/ -v ./data/:/var/cache/searxng/ searxng/searxng:latest"
      "docker run -d --dns=9.9.9.9 --restart unless-stopped -p 80:8080  -v ./config/:/etc/searxng/ -v ./data/:/var/cache/searxng/ ghcr.io/searxng/searxng:2026.1.16-2d9f213ca"
    ]
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true
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
      "docker run -d --restart unless-stopped -it --name n8n -p 5678:5678 -e GENERIC_TIMEZONE='America/New_York' -e TZ='America/New_York' -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true -e N8N_RUNNERS_ENABLED=true -e N8N_SECURE_COOKIE=false -e DB_SQLITE_POOL_SIZE=5 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n"
    ]
    connection {
      type  = "ssh"
      user  = "root"
      host  = split("/", self.initialization[0].ip_config[0].ipv4[0].address)[0]
      agent = true
    }
  }
}

