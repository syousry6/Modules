# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "subnet_ids" {
  type        = list(string)
  description = "A list of VPC subnet IDs"
  default     = []
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "default" {
  count = var.create ? 1 : 0

  name        = local.stage_prefix
  description = "Database subnet group"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.tags,
    {
      "Name" = "RDS_subnet_group"
    },
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_subnet_group_id" {
  description = "The db subnet group name"
  value       = element(concat(aws_db_subnet_group.default.*.id, [""]), 0)
}

output "rds_db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = element(concat(aws_db_subnet_group.default.*.arn, [""]), 0)
}

