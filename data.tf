data "google_projects" "firebase_projects" {
  filter = "labels.firebase:enabled"
}

data "aws_s3_bucket" "google_cloud_service_accounts_bucket" {
  bucket = "bfan-google-cloud-service-accounts"
}
