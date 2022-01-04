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

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible"
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  default     = true
}

variable "engine_version" {
  description = "The engine version to use"
}


variable "rds_name"{
}


variable "rds_instance_class"{
}

variable "rds_engine"{
    type        = string
    default     = ""
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
}


variable "rds_sg"{
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
  default     = ""
}


variable "option_group_name" {
  description = "Name of the DB option group to associate."
  default     = ""
}


variable "db_subnet_group_name" {
  description = "Name of the subnet group to associate."
  default     = ""
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Must be specified if monitoring_interval is non-zero."
  default     = ""
}


variable "parameter_store_kms_arn" {
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
  type        = string
  default     = "alias/parameter_store_key"
}

variable "monitoring_role_name" {
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled."
  default     = "rds-monitoring-role"
}

variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs."
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = ""
}



data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

data "aws_kms_key" "rds_kms" {
  key_id  = "alias/macewan/non/prd/rds"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
}

# variable "license_model" {
#   description = "License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1"
#   default     = ""
# }

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.create_monitoring_role ? 1 : 0

  name               = var.monitoring_role_name
  assume_role_policy = file("${path.module}/policy/enhancedmonitoring.json")
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.create_monitoring_role ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


resource "random_password" "rds_password" {
  count = var.create ? 1 : 0

  length      = 16
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  min_special = 4
  # override_special = "/@\" "
}

resource "aws_ssm_parameter" "rds_password" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-password"
  description = "Oracle RDS Service Password"
  tags        = local.tags

  type = "SecureString"
  key_id    = coalesce(data.aws_kms_key.parameter_store_key.key_id, var.parameter_store_kms_arn, "")
  value     = random_password.rds_password[0].result
  overwrite = true
}


resource "aws_db_instance" "default" {
  username                        = "MacewanAdminDB"
  password                        = random_password.rds_password[0].result
  identifier                      = var.rds_name
  allocated_storage               = var.allocated_storage
  # max_allocated_storage           = var.max_allocated_storage
  backup_retention_period         = var.backup_retention_period
  parameter_group_name            = var.parameter_group_name
  option_group_name               = var.option_group_name
  multi_az                        = var.multi_az
  db_subnet_group_name            = var.db_subnet_group_name
  kms_key_id                      = data.aws_kms_key.rds_kms.arn
  license_model                   = "license-included"
  storage_encrypted               = true
  vpc_security_group_ids          = [var.rds_sg]
  engine                          = var.rds_engine
  engine_version                  = var.engine_version
  instance_class                  = var.rds_instance_class 
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  # monitoring_role_arn = coalesce(
  #   var.monitoring_role_arn,
  #   join("", aws_iam_role.enhanced_monitoring.*.arn),
  # )

  final_snapshot_identifier       = "${var.rds_name}-final-version"
  tags                            = merge(
     local.tags,
    {
      Name = var.rds_name
    }
  )
  lifecycle {
    ignore_changes = [
      password
    ]
  }

  timeouts {
    create = "90m"
  }
   
}
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "rds_id" {
  value = aws_db_instance.default.id
}

output "rds_address" {
  value = aws_db_instance.default.address
}

