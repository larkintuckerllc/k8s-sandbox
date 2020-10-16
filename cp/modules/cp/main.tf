locals {
  name = "k8s-cp"
}

data "google_compute_image" "this" {
  name = var.image_name
}

resource "google_service_account" "this" {
  account_id   = local.name
  display_name = local.name
}

resource "google_project_iam_binding" "this" {
  members = [
    "serviceAccount:${google_service_account.this.email}"
  ]
  role = "roles/secretmanager.admin"
}

resource "google_compute_instance_template" "this" {
  disk {
    source_image = data.google_compute_image.this.self_link
    boot         = true
  }
  machine_type = "e2-medium"
  name         = local.name
  network_interface {
    access_config {
      network_tier = "STANDARD"
    }
    network = "default"
  }
  service_account {
    email = google_service_account.this.email
    scopes = ["cloud-platform"]
  }
  tags = [
    local.name
  ]
}

resource "google_compute_target_pool" "this" {
  name   = local.name
  region = var.region
}

resource "google_compute_region_instance_group_manager" "this" {
  lifecycle {
    ignore_changes = [target_size]
  }
  base_instance_name = local.name
  name               = local.name
  region             = var.region
  target_pools = [
    google_compute_target_pool.this.id
  ]
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.this.id
    name              = local.name
  }
}

resource "google_compute_address" "this" {
  name       = local.name
  region     = var.region
}

resource "google_compute_forwarding_rule" "this" {
  ip_address  = google_compute_address.this.address
  ip_protocol = "TCP"
  name        = local.name
  port_range  = "6443"
  region      = var.region
  target      = google_compute_target_pool.this.self_link
}

resource "google_compute_firewall" "this" {
  allow {
    ports = [
      "6443"
    ]
    protocol = "tcp"
  }
  name     = "allow-6443-target-${local.name}"
  network  = "default"
  priority = 1000
  target_tags = [
    local.name
  ]
}
