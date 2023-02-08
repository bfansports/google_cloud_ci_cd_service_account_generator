terraform {
  backend "s3" {
    bucket = "bfan-google-cloud-service-accounts"
    key    = "google_cloud_ci_cd_service_account_generator.tfstate"
  }
}
