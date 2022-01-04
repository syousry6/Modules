# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
# variable "map_migrated" {
#   type        = string
#   default     = "d-server-01h73qzcsagfqf"
#   description = ""
# }


# variable "aws_migration_project_id" {
#   type        = string
#   default     = "MPE26978"
#   description = ""
# }

# variable "rds_pg_name"{}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
# resource "aws_db_parameter_group" "MsSql_pg" {
#   name        = var.rds_pg_name
#   family      = "${var.rds_engine}-${var.engine_version}.0"
#   description = "MS sql server parameter group"
  
#   parameter {
#     name  = "rds.force_ssl"
#     value = "1"
#     apply_method  = "pending-reboot"
#   }
#  tags = merge(
#     local.tags,
#     {
#       Name = "${var.rds_engine}-parameter-group"
#     }
#   )
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
# output "pg_id" {
#   value = aws_db_parameter_group.MsSql_pg.id
# }



###

# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "map_migrated" {
  type        = string
  default     = "d-server-01h73qzcsagfqf"
  description = ""
}

variable "aws_migration_project_id" {
  type        = string
  default     = "MPE26978"
  description = ""
}

variable "family" {
  description = "The family of the DB parameter group"
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  default     = []
  type        = list(map(string))
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_db_parameter_group" "default" {
  count = var.create ? 1 : 0

  name        = "rds-db-parameter-group"
  description = "Default database parameter group"
  family      = var.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "Default parameter group"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_parameter_group_id" {
  description = "The db parameter group id"
  value       = element(split(",", join(",", aws_db_parameter_group.default.*.id)), 0)
}

output "rds_db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = element(split(",", join(",", aws_db_parameter_group.default.*.arn)), 0)
}

