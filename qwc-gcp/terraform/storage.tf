# Cloud Storage bucket for QGIS resources
resource "google_storage_bucket" "qgis_resources" {
  name          = "${var.project-name}-qgis-resources"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

# Cloud Storage bucket for print layouts
resource "google_storage_bucket" "print_layouts" {
  name          = "${var.project-name}-print-layouts"
  location      = var.location
  storage_class = var.storage-class

  uniform_bucket_level_access = true
}