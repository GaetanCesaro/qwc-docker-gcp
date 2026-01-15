# Secret for Postgres password
resource "google_secret_manager_secret" "postgres-password" {
  project   = var.project-name
  secret_id = "postgres-password"

  replication {
    user_managed {
      replicas {
        location = "europe-west1"
      }
    }
  }
}
resource "google_secret_manager_secret_version" "postgres-password-version" {
  secret      = google_secret_manager_secret.postgres-password.id
  secret_data = var.postgres-password
}

# Secret for pg_service.conf
resource "google_secret_manager_secret" "pg_service_conf" {
  secret_id = "pg-service-conf-${var.project_env}"
  project   = var.project-name

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret]
}

resource "google_secret_manager_secret_version" "pg_service_conf" {
  secret = google_secret_manager_secret.pg_service_conf.id

  # Replace with the actual content of your pg_service.conf
  secret_data = file("${path.module}/../../pg_service.gcp.conf")
}
