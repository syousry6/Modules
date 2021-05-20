# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cloudwatch_log_group_name" {
  type        = string
  default     = ""
  description = "The name of the log group"
}

variable "cloudwatch_log_group_retention" {
  description = "Specifies the number of days you want to retain log events in the specified log"
  type        = number
  default     = 14
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ds_logging" {
  count = var.create && var.cloudwatch_log_group_name == "" ? 1 : 0
  name  = format("/aws/directoryservice/%s", aws_directory_service_directory.ds[0].id)

  retention_in_days = var.cloudwatch_log_group_retention
}

data "aws_iam_policy_document" "ds_logging" {
  count = var.create ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    principals {
      identifiers = ["ds.amazonaws.com"]
      type        = "Service"
    }
    resources = [aws_cloudwatch_log_group.ds_logging[0].arn]
  }
}

resource "aws_cloudwatch_log_resource_policy" "ds_logging" {
  count = var.create ? 1 : 0

  policy_document = data.aws_iam_policy_document.ds_logging[0].json
  policy_name     = format("%s-log-access", local.module_prefix)
}

resource "aws_directory_service_log_subscription" "ds_logging" {
  count = var.create ? 1 : 0

  directory_id   = aws_directory_service_directory.ds[0].id
  log_group_name = coalesce(var.cloudwatch_log_group_name, aws_cloudwatch_log_group.ds_logging[0].name)
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
