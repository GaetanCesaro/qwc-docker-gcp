# cloud-sql-proxy SA
resource "google_service_account" "cloud_sql_proxy" {
  account_id   = "cloud-sql-proxy"
  display_name = "Service Account for Cloud SQL Proxy"
}

resource "google_project_iam_member" "cloud_sql_proxy_sql_client" {
  project = var.project-name
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_proxy.email}"
}

# Terraform SA
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Service Account for Terraform"
}

resource "google_project_iam_member" "terraform_sa_scheduler_admin" {
  project = var.project-name
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}
resource "google_project_iam_member" "terraform_sa_editor" {
  project = var.project-name
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# qwc-qgis-server SA
resource "google_service_account" "qwc_qgis_server" {
  account_id   = "qwc-qgis-server-${var.project_env}"
  display_name = "QWC QGIS Server Service Account"
  project      = var.project-name
}

resource "google_project_iam_member" "qgis_server_sql_client" {
  project = var.project-name
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.qwc_qgis_server.email}"
}
resource "google_storage_bucket_iam_member" "qgis_resources_viewer" {
  bucket = google_storage_bucket.qgis_resources.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.qwc_qgis_server.email}"
}
resource "google_storage_bucket_iam_member" "print_layouts_viewer" {
  bucket = google_storage_bucket.print_layouts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.qwc_qgis_server.email}"
}
resource "google_secret_manager_secret_iam_member" "qgis_server_secret_accessor" {
  secret_id = google_secret_manager_secret.pg_service_conf.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.qwc_qgis_server.email}"
}
