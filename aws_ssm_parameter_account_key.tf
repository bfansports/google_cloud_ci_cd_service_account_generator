resource "aws_ssm_parameter" "firebase_service_account_key" {
  count = length(data.google_projects.firebase_projects.projects)
  name  = "/google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/${data.google_projects.firebase_projects.projects[count.index].project_id}"
  type  = "SecureString"
  value = base64decode(google_service_account_key.firebase_service_account_key[count.index].private_key)
}
