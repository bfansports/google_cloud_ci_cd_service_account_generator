# We will be using environment variables
provider "aws" {
}

# We will be using the default credentials from
# `gcloud auth application-default login
provider "google" {
    request_reason = "google_cloud_ci_cd_service_account_generator"
}

provider "time" {
}
