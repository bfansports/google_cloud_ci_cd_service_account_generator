locals {
  aws_profile = split("/", get_path_from_repo_root())[0]
  terraform_bucket_name = "bfan-terraform-state-bucket-${split("-", local.aws_profile)[0]}"
  module_name = split("/", get_path_from_repo_root())[1]
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    profile        = "${local.aws_profile}"
    bucket         = "${local.terraform_bucket_name}"
    key            = "${local.module_name}.tfstate"
    region         = "eu-west-1"
    # dynamodb_table = "terraform-state-lock" # TODO: Create a DynamoDB table for state locking
  }
}
EOF
}

# ╷
# │ Error: Provider produced inconsistent result after apply
# │
# │ When applying changes to
# │ google_service_account_key.firebase_service_account_key["fclausannesport-b65e6"],
# │ provider "provider[\"registry.terraform.io/hashicorp/google\"]" produced an
# │ unexpected new value: Root object was present, but now absent.
# │
# │ This is a bug in the provider, which should be reported in the provider's
# │ own issue tracker.
# ╵
retryable_errors = [
  "(?s).*Root object was present, but now absent.*"
]
retry_max_attempts = 5
retry_sleep_interval_sec = 60

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  profile = "${local.aws_profile}"
  region  = "eu-west-1"
}
EOF
}

terraform {
  source = "../../modules/${local.module_name}"
}
inputs = {
  aws_env_name = "${local.aws_profile}"
}