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