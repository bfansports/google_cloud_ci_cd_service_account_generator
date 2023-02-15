# One provider per AWS account
provider "aws" {
  profile = "dev-eu"
  region  = "eu-west-1"
  alias   = "dev-eu"
}
provider "aws" {
  profile = "qa-eu"
  region  = "eu-west-1"
  alias   = "qa-eu"
}
provider "aws" {
  profile = "prod-eu"
  region  = "eu-west-1"
  alias   = "prod-eu"
}

# We will be using the default credentials from
# `gcloud auth application-default login
provider "google" {
  request_reason = "google_cloud_ci_cd_service_account_generator"
}

provider "time" {
}
