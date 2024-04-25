# Auto rotate the firebase service account key for added security
resource "time_rotating" "firebase_service_account_key_rotation" {
  rotation_minutes = 30 # note this requires the terraform to be run regularly
}

resource "google_service_account_key" "firebase_service_account_key" {
  count              = length(data.google_projects.firebase_projects.projects)
  service_account_id = google_service_account.firebase_service_account[count.index].name
  keepers = {
    rotation_time = time_rotating.firebase_service_account_key_rotation.rotation_rfc3339
  }
}
