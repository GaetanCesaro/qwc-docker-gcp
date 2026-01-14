resource "google_cloud_scheduler_job" "sql_stop_instance" {
  project = ""
  name             = "sql-stop-instance"
  schedule         = "0 19 * * 1-5"
  description      = "Stop SQL Instance"
  time_zone        = "Europe/Paris"
  region           = var.region-serverless
  attempt_deadline = "1200s"

  retry_config {
    min_backoff_duration = "5s"
    max_retry_duration = "0s"
    max_doublings = 5
    retry_count = 0
  }

  http_target {
      http_method = "PATCH"
      uri         = format("https://sqladmin.googleapis.com/v1/projects/%s/instances/eauphrate", var.project-name)
      headers = {
        "Content-Type" = "application/octet-stream",
        "User-Agent"   = "Google-Cloud-Scheduler"
      }
      body        = base64encode("{\"settings\":{\"activationPolicy\": \"NEVER\"}}")

      oauth_token {
        service_account_email   = "terraform-sa@${var.project-name}.iam.gserviceaccount.com"
        scope                   = "https://www.googleapis.com/auth/cloud-platform"
      }
    }
}

resource "google_cloud_scheduler_job" "sql_start_instance" {
  project = ""
  name             = "sql-start-instance"
  schedule         = "30 8 * * 1-5"
  description      = "Start SQL Instance"
  time_zone        = "Europe/Paris"
  region           = var.region-serverless
  attempt_deadline = "1200s"

  retry_config {
    min_backoff_duration = "5s"
    max_retry_duration = "0s"
    max_doublings = 5
    retry_count = 0
  }

  http_target {
      http_method = "PATCH"
      uri         = format("https://sqladmin.googleapis.com/v1/projects/%s/instances/eauphrate", var.project-name)
      headers = {
        "Content-Type" = "application/octet-stream",
        "User-Agent"   = "Google-Cloud-Scheduler"
      }
      body        = base64encode("{\"settings\":{\"activationPolicy\": \"ALWAYS\"}}")

      oauth_token {
        service_account_email   = "terraform-sa@${var.project-name}.iam.gserviceaccount.com"
        scope                   = "https://www.googleapis.com/auth/cloud-platform"
      }
    }
}