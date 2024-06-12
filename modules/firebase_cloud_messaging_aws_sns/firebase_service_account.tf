resource "google_service_account" "firebase_service_account" {
  for_each     = toset(values(local.org_id_to_project_id))
  account_id   = "bfan-firebase-fcm-sns-${var.aws_env_name}"
  display_name = "bFAN Firebase Service Account for AWS SNS"
  description  = "Service account used by AWS SNS to send push notifications via Firebase Cloud Messaging"
  project      = each.value
}

# Grant it Firebase Admin role
resource "google_project_iam_member" "firebase_cloud_messaging_admin" {
  for_each = toset(values(local.org_id_to_project_id))
  project  = each.value
  role     = "roles/firebasemessagingcampaigns.admin"
  member   = "serviceAccount:${google_service_account.firebase_service_account[each.key].email}"
}
