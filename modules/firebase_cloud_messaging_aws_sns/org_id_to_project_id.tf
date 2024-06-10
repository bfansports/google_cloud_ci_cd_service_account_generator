# aws dynamodb scan \
#     --table-name Organizations \
#     --projection-expression "id, firebase_project_id" \
#     --filter-expression "attribute_exists(firebase_project_id) AND attribute_type(firebase_project_id, :stringType)" \
#     --expression-attribute-values "{\":stringType\":{\"S\": \"S\"}}" \
#     --output json \
#     --query "Items"
module "aws_organizations_firebase_project_ids" {
  source  = "digitickets/cli/aws"
  version = "6.1.0"
  profile = var.aws_env_name
  aws_cli_commands = [
    "dynamodb",
    "scan",
    "--table-name=Organizations",
    "--filter-expression=\"attribute_exists(firebase_project_id) AND attribute_type(firebase_project_id, :stringType)\"",
    "--expression-attribute-values '{\":stringType\":{\"S\": \"S\"}}'"
  ]
  aws_cli_query = "Items"
}

locals {
  org_id_to_project_id = {
    for item in module.aws_organizations_firebase_project_ids.result : item.id.S => item.firebase_project_id.S
  }
}

# output "org_id_to_project_id" {
#   value = local.org_id_to_project_id
# }