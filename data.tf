data "google_projects" "firebase_projects" {
  filter = "labels.firebase:enabled"
}
