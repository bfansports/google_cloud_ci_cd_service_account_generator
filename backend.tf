terraform {
  backend "s3" {
    region  = "eu-west-1"
    bucket  = "bfan-terraform-state-bucket"
    key     = "google_cloud_ci_cd_service_account_generator.tfstate"
    profile = "prod-eu"
  }
}
