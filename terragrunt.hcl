locals {
  aws_profile = get_env("AWS_PROFILE")
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
retryable_errors         = ["(?s).*Root object was present, but now absent.*"]
retry_max_attempts       = 5
retry_sleep_interval_sec = 60

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "${local.aws_profile}"
  region  = "eu-west-1"
}
EOF
}
