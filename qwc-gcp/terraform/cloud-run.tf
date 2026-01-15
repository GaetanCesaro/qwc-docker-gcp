# Cloud Run service for qwc-qgis-server
resource "google_cloud_run_v2_service" "qgis_server" {
  name     = "qwc-qgis-server-${var.project_env}"
  location = var.region-serverless
  project  = var.project-name

  template {
    service_account = google_service_account.qwc_qgis_server.email

    # Cloud SQL connection
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.instance.connection_name]
      }
    }

    # Mount pg_service.conf from Secret Manager
    volumes {
      name = "pg-service"
      secret {
        secret = google_secret_manager_secret.pg_service_conf.secret_id
        items {
          version = "latest"
          path    = "pg_service.conf"
        }
      }
    }

    containers {
      # Custom image with Cloud Storage FUSE support
      # Build and push using: cd qwc-gcp/qgis-server && ./build-qgis-server.sh <project-id> <env>
      image = "gcr.io/${var.project-name}/qwc-qgis-server:${var.project_env}"

      # Environment variables for Cloud Storage FUSE
      env {
        name  = "GCS_PROJECT_NAME"
        value = var.project-name
      }

      env {
        name  = "GCS_QGIS_RESOURCES_BUCKET"
        value = google_storage_bucket.qgis_resources.name
      }

      env {
        name  = "GCS_PRINT_LAYOUTS_BUCKET"
        value = google_storage_bucket.print_layouts.name
      }

      # Environment variables from docker-compose.yml
      env {
        name  = "FCGID_EXTRA_ENV"
        value = "PRINT_LAYOUT_DIR"
      }

      env {
        name  = "PRINT_LAYOUT_DIR"
        value = "/layouts"
      }

      env {
        name  = "QGIS_SERVER_LOG_LEVEL"
        value = "0"
      }

      env {
        name  = "LOCALE"
        value = "fr_FR"
      }

      env {
        name  = "QGIS_SERVER_IGNORE_BAD_LAYERS"
        value = "1"
      }

      # Mount Cloud SQL socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Mount pg_service.conf
      volume_mounts {
        name       = "pg-service"
        mount_path = "/etc/postgresql-common"
      }

      # Resources
      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      # Startup probe
      startup_probe {
        http_get {
          path = "/"
          port = 80
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }

      # Liveness probe
      liveness_probe {
        http_get {
          path = "/"
          port = 80
        }
        initial_delay_seconds = 30
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    # Scaling configuration
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    # Timeout
    timeout = "300s"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_service.run,
    google_sql_database_instance.instance
  ]
}

# IAM policy to allow unauthenticated access (adjust based on your needs)
resource "google_cloud_run_v2_service_iam_member" "qgis_server_public" {
  name     = google_cloud_run_v2_service.qgis_server.name
  location = google_cloud_run_v2_service.qgis_server.location
  project  = var.project-name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the service URL
output "qgis_server_url" {
  value       = google_cloud_run_v2_service.qgis_server.uri
  description = "URL of the QWC QGIS Server on Cloud Run"
}
