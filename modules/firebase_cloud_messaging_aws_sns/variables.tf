variable "aws_env_name" {
  type        = string
  nullable    = false
  description = "AWS Environment name"
}

variable "org_id_to_project_id" {
  type        = map(string)
  nullable    = false
  description = "Map of organisation ID to Firebase project ID, e.g. { \"stadefrancais\" = \"bfan-stadefrancais\" }"
}

variable "excluded_project_ids" {
  type        = set(string)
  default     = []
  description = "Project IDs to exclude from service account key creation and IAM bindings (e.g. projects with iam.disableServiceAccountKeyCreation org policy)"
}
