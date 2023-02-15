resource "aws_ssm_parameter" "firebase_service_account_key-dev-eu" {
  provider = aws.dev-eu
  count    = length(data.google_projects.firebase_projects.projects)
  name     = "/google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/${data.google_projects.firebase_projects.projects[count.index].project_id}"
  type     = "SecureString"
  value    = base64decode(google_service_account_key.firebase_service_account_key[count.index].private_key)
}

resource "aws_ssm_parameter" "firebase_service_account_key-qa-eu" {
  provider = aws.qa-eu
  count    = length(data.google_projects.firebase_projects.projects)
  name     = "/google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/${data.google_projects.firebase_projects.projects[count.index].project_id}"
  type     = "SecureString"
  value    = base64decode(google_service_account_key.firebase_service_account_key[count.index].private_key)
}

resource "aws_ssm_parameter" "firebase_service_account_key-prod-eu" {
  provider = aws.prod-eu
  count    = length(data.google_projects.firebase_projects.projects)
  name     = "/google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/${data.google_projects.firebase_projects.projects[count.index].project_id}"
  type     = "SecureString"
  value    = base64decode(google_service_account_key.firebase_service_account_key[count.index].private_key)
}
