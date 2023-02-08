resource "aws_s3_object" "aws_s3_object_firebase_service_account_key" {
  count          = length(data.google_projects.firebase_projects.projects)
  bucket         = data.aws_s3_bucket.google_cloud_service_accounts_bucket.bucket
  key            = "firebase_service_account_keys/${data.google_projects.firebase_projects.projects[count.index].project_id}.json"
  content_base64 = google_service_account_key.firebase_service_account_key[count.index].private_key
}
