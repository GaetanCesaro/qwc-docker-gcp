# GKE Cluster pour les services QWC
resource "google_container_cluster" "qwc_cluster" {
  name     = "qwc-cluster-${var.project_env}"
  location = var.zone
  project  = var.project-name

  # Mode autopilot ou standard
  # Utiliser Standard pour plus de contrôle sur les nodes

  # Supprimer le node pool par défaut car nous en créons un personnalisé
  remove_default_node_pool = true
  initial_node_count       = 1

  # Configuration réseau
  network    = "default"
  subnetwork = "default"

  # Activer Workload Identity pour l'authentification avec GCP
  workload_identity_config {
    workload_pool = "${var.project-name}.svc.id.goog"
  }

  # Configuration de sécurité
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Protection contre la suppression accidentelle
  deletion_protection = false

  depends_on = [google_project_service.gke]
}

# Node Pool personnalisé
resource "google_container_node_pool" "qwc_nodes" {
  name     = "qwc-node-pool-${var.project_env}"
  location = var.zone
  cluster  = google_container_cluster.qwc_cluster.name
  project  = var.project-name

  # Autoscaling
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  # Configuration des nodes
  node_config {
    machine_type = "e2-medium" # 2 vCPUs, 4 GB RAM
    disk_size_gb = 50
    disk_type    = "pd-standard"

    # Permissions nécessaires
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    # Service account pour les nodes
    service_account = google_service_account.gke_nodes.email

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels
    labels = {
      env     = var.project_env
      cluster = "qwc"
    }

    # Taints pour isolation (optionnel)
    # taint {
    #   key    = "workload"
    #   value  = "qwc"
    #   effect = "NO_SCHEDULE"
    # }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Mise à jour automatique des nodes
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account pour les nodes GKE
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes-${var.project_env}"
  display_name = "GKE Node Pool Service Account"
  project      = var.project-name
}

# Permissions pour les nodes
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project-name
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project-name
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project-name
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Accès aux buckets GCS pour le node pool
resource "google_storage_bucket_iam_member" "gke_config_in_viewer" {
  bucket = google_storage_bucket.config_in.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_storage_bucket_iam_member" "gke_config_admin" {
  bucket = google_storage_bucket.config.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Outputs
output "gke_cluster_name" {
  value       = google_container_cluster.qwc_cluster.name
  description = "GKE Cluster Name"
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.qwc_cluster.endpoint
  description = "GKE Cluster Endpoint"
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  value       = google_container_cluster.qwc_cluster.master_auth[0].cluster_ca_certificate
  description = "GKE Cluster CA Certificate"
  sensitive   = true
}
