terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = "tactile-oxygen-435023-b2"
  region  = "europe-west3"
}


# Network & Firewall
resource "google_compute_network" "vpc_network" {
  name = "internal-network"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_kibana" {
  name    = "allow-kibana"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["kibana"]
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.128.0.0/9"]
}

# VMs

# Define a map for VM configurations
locals {
  vm_configs = {
    "instance-siem" = { type = "e2-highcpu-4", ip = "static-ip-1", tags = ["kibana"] }
    "instance-client" = { type = "e2-highcpu-2", ip = "static-ip-2", tags = [] }
    "instance-client2" = { type = "e2-highcpu-2", ip = "static-ip-3", tags = [] }
  }
}


# Create multiple static IPs using for_each
resource "google_compute_address" "static_ips" {
  for_each = local.vm_configs
  name     = each.value.ip
}


# Create multiple VM instances using for_each
resource "google_compute_instance" "vm_instances" {
  for_each     = local.vm_configs
  name         = each.key
  machine_type = each.value.type
  zone         = "europe-west3-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20240904"
      size  = 30
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name

    access_config {
      nat_ip = google_compute_address.static_ips[each.key].address
    }
  }

  tags = each.value.tags

  metadata = {
    "ssh-keys" = "shpetim:${file("id_rsa.pub")}"
  }
}


# Create a Cloud DNS Managed Zone for internal use
resource "google_dns_managed_zone" "internal_zone" {
  name     = "internal-zone"
  dns_name = "tiramisu.int."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.self_link
    }
  }
}

# Create internal DNS Records for each VM
resource "google_dns_record_set" "dns_records" {
  for_each = google_compute_instance.vm_instances

  managed_zone = google_dns_managed_zone.internal_zone.name
  name         = "${each.key}.tiramisu.int."  # Subdomain for each VM
  type         = "A"
  ttl          = 300
  rrdatas      = [each.value.network_interface[0].network_ip]  # Use dynamically assigned internal IPs
}