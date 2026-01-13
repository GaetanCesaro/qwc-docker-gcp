# Add a cloud-sql-proxy service account granted with Cloud SQL Client role
resource "google_service_account" "cloud_sql_proxy" {
  account_id   = "cloud-sql-proxy"
  display_name = "Service Account for Cloud SQL Proxy"
}

resource "google_project_iam_member" "cloud_sql_proxy_sql_client" {
  project = var.project-name
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_proxy.email}"
}