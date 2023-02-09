terraform {
  backend "s3" {
    bucket = "bfan-terraform-state-bucket"
    key    = "google_cloud_ci_cd_service_account_generator.tfstate"
  }
}
