provider "hcloud" {
  token = var.hcloud_token
}

locals {
  nodes = {
    "sre-cp-01" = {
      role       = "control-plane"
      private_ip = "10.10.0.10"
    }
    "sre-worker-01" = {
      role       = "worker"
      private_ip = "10.10.0.11"
    }
    "sre-worker-02" = {
      role       = "worker"
      private_ip = "10.10.0.12"
    }
  }
}

resource "hcloud_ssh_key" "management" {
  name       = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_network" "k8s" {
  name     = "${var.project_name}-network"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "k8s" {
  network_id   = hcloud_network.k8s.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.network_cidr
}

resource "hcloud_firewall" "k8s" {
  name = "${var.project_name}-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.admin_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.admin_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [var.admin_cidr]
  }
}

resource "hcloud_server" "node" {
  for_each = local.nodes

  name         = each.key
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.management.id]
  firewall_ids = [hcloud_firewall.k8s.id]

  labels = {
    project = var.project_name
    role    = each.value.role
  }

  network {
    network_id = hcloud_network.k8s.id
    ip         = each.value.private_ip
  }

  depends_on = [hcloud_network_subnet.k8s]
}
