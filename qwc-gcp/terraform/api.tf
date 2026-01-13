resource "google_project_service" "secret" {
  project = var.project-name
  service = "secretmanager.googleapis.com"
  disable_dependent_services = false
}

# Add Cloud SQL Admin API 
resource "google_project_service" "sqladmin" {
  project = var.project-name
  service = "sqladmin.googleapis.com"
  disable_dependent_services = false
}