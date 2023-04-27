terraform {
  # Broken due to
  # https://github.com/hashicorp/terraform/issues/32465
  # backend "s3" {
  #   region  = "eu-west-1"
  #   bucket  = "bfan-terraform-state-bucket"
  #   key     = "google_cloud_ci_cd_service_account_generator.tfstate"
  #   profile = "prod-eu"
  # }
  # TODO: Go back to S3 backend one the issue is fixed
  backend "local" {
  }
}
