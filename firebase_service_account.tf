resource "google_service_account" "firebase_service_account" {
  count        = length(data.google_projects.firebase_projects.projects)
  account_id   = "onprem-bfan-firebase-ci-cd"
  display_name = "bFAN Firebase CI/CD Service Account"
  description  = "Service account used by the CI/CD to deploy Firebase resources"
  project      = data.google_projects.firebase_projects.projects[count.index].project_id
}

# Grant it Firebase Admin role
resource "google_project_iam_member" "firebase_admin" {
  count   = length(data.google_projects.firebase_projects.projects)
  project = data.google_projects.firebase_projects.projects[count.index].project_id
  role    = "roles/firebase.admin"
  member  = "serviceAccount:${google_service_account.firebase_service_account[count.index].email}"
}
