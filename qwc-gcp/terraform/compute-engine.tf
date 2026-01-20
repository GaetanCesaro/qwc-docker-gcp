# Compute Engine instance for QWC QGIS Server
resource "google_compute_instance" "qwc_qgis_server" {
  name         = "qwc-qgis-server-${var.project_env}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
      #   nat_ip = google_compute_address.qwc_qgis_server.address
    }
  }

  service_account {
    email  = google_service_account.qwc_qgis_server.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
    user-data = templatefile("${path.module}/compute-engine/cloud-init.yaml", {
      project_name               = var.project-name
      project_env                = var.project_env
      qgis_resources_bucket      = google_storage_bucket.qgis_resources.name
      print_layouts_bucket       = google_storage_bucket.print_layouts.name
      qgis_server_plugins_bucket = google_storage_bucket.qgis_server_plugins.name
      pg_service_secret          = google_secret_manager_secret.pg_service_conf.secret_id
      db_instance_name           = google_sql_database_instance.instance.connection_name
    })
  }

  tags = ["qwc-qgis-server"]

  labels = {
    environment = var.project_env
    component   = "qgis-server"
  }
}

# Firewall rule to allow access to QGIS server (port 80)
resource "google_compute_firewall" "qwc_qgis_server" {
  name    = "allow-qwc-qgis-server-${var.project_env}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.0.0.0/8"] # Adjust according to your network
  target_tags   = ["qwc-qgis-server"]
}

# Static IP address for the QGIS server (optional)
# Uncomment if you need a static IP address
# resource "google_compute_address" "qwc_qgis_server" {
#   name   = "qwc-qgis-server-ip-${var.project_env}"
#   region = var.region
# }

# Output the IP address
output "qgis_server_ip" {
  value       = google_compute_instance.qwc_qgis_server.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the QGIS server"
}

output "qgis_server_internal_ip" {
  value       = google_compute_instance.qwc_qgis_server.network_interface[0].network_ip
  description = "Internal IP address of the QGIS server"
}
