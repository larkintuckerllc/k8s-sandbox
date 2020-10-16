locals {
  name = "k8s-wk"
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
  role = "roles/secretmanager.secretAccessor"
}

resource "google_compute_instance_template" "this" {
  disk {
    source_image = data.google_compute_image.this.self_link
    boot         = true
  }
  machine_type = "e2-medium"
  metadata = {
    "shutdown-script" = <<EOF
gcloud secrets versions access latest --secret=bootstrapper-config > /tmp/config
kubectl --kubeconfig=/tmp/config drain $(hostname) --delete-local-data --force --ignore-daemonsets
kubectl --kubeconfig=/tmp/config delete node $(hostname)
EOF
  }
  metadata_startup_script = <<EOF
IP=$(gcloud secrets versions access latest --secret=bootstrapper-ip)
HASH=$(gcloud secrets versions access latest --secret=bootstrapper-hash)
ID=$(gcloud secrets versions access latest --secret=bootstrapper-id)
SECRET=$(gcloud secrets versions access latest --secret=bootstrapper-secret)
kubeadm join $IP:6443 \
--token $ID.$SECRET \
--discovery-token-ca-cert-hash sha256:$HASH
EOF
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
}

resource "google_compute_region_instance_group_manager" "this" {
  lifecycle {
    ignore_changes = [target_size]
  }
  base_instance_name = local.name
  name               = local.name
  region             = var.region
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.this.id
    name              = local.name
  }
}
