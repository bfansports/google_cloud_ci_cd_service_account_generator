data "aws_caller_identity" "current" {}
locals {
  env_name       = split("-", var.aws_env_name)[0]
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_sns_platform_application" "fcm_application" {
  for_each = local.org_id_to_project_id
  name     = "${upper(each.key)}-ANDROID-${upper(local.env_name)}"
  platform = "GCM"

  platform_credential = base64decode(google_service_account_key.firebase_service_account_key[each.value].private_key)

  event_endpoint_created_topic_arn = "arn:aws:sns:eu-west-1:${local.aws_account_id}:bFanCreateEvents"
  event_endpoint_deleted_topic_arn = "arn:aws:sns:eu-west-1:${local.aws_account_id}:bFanDeleteEvents"
  event_endpoint_updated_topic_arn = "arn:aws:sns:eu-west-1:${local.aws_account_id}:bFanUpdateEvents"

  failure_feedback_role_arn    = "arn:aws:iam::${local.aws_account_id}:role/SNSFailureFeedback"
  success_feedback_role_arn    = "arn:aws:iam::${local.aws_account_id}:role/SNSSuccessFeedback"
  success_feedback_sample_rate = 100
}