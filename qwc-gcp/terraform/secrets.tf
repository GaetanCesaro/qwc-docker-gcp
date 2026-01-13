resource "google_secret_manager_secret" "postgres-password" {
  project = var.project-name
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
  secret = google_secret_manager_secret.postgres-password.id
  secret_data = var.postgres-password
}