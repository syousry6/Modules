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


variable "identifier" {
  description = "The identifier of the resource"
  default     = "default rds"
}

variable "option_group_description" {
  description = "The description of the option group"
  default     = ""
}

variable "engine_name" {
  description = "Specifies the name of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Specifies the name of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "options" {
  type        = list(string)
  description = "A list of Options to apply"
  default     = []
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  default     = "alias/macewan/non/prd/rds"
}

data "aws_kms_key" "rds_kms" {
  key_id = "arn:aws:kms:us-west-2:907193732944:key/96ce2996-3248-4e82-b59a-0d270f0c99ea"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "rds_backup_restore" {
  count  = var.create ? 1 : 0
  bucket = "${var.module_prefix}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "rds_backup_restore_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_backup_restore" {
  count              = var.create ? 1 : 0
  name               = join("-", [local.module_prefix, "backup-restore-role"])
  description        = "Macewan Module: Role to allow RDS to access S3 for DB backup and restore purposes"
  assume_role_policy = data.aws_iam_policy_document.rds_backup_restore_trust.json

  tags = local.tags
}

data "aws_iam_policy_document" "rds_backup_restore" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [data.aws_kms_key.rds_kms.key_id]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [aws_s3_bucket.rds_backup_restore[0].arn]
  }

  statement {
    actions = [
      "s3:GetObjectMetaData",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]

    resources = ["${aws_s3_bucket.rds_backup_restore[0].arn}/*"]
  }
}

resource "aws_iam_role_policy" "rds_backup_restore" {
  count = var.create ? 1 : 0
  name  = "rds-backup-restore-policy"
  role  = aws_iam_role.rds_backup_restore[0].id

  policy = data.aws_iam_policy_document.rds_backup_restore[0].json
}

resource "aws_db_option_group" "default" {
  count = var.create ? 1 : 0
  name                     = "rds-db-option-group"
  option_group_description = var.option_group_description == "" ? format("Option group for %s", var.identifier) : var.option_group_description
  engine_name              = var.engine_name
  major_engine_version     = var.major_engine_version

  option {
    option_name = "S3_INTEGRATION" 
    version     = "1.0"

    # option_settings {
    #   name  = "IAM_ROLE_ARN"
    #   value = aws_iam_role.rds_backup_restore[0].arn
    # }
  }

  tags = merge(
    local.tags,
    {
      Name = local.module_prefix
    }
  )  

  lifecycle {
    create_before_destroy = true
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_option_group_id" {
  description = "The db option group id"
  value       = element(split(",", join(",", aws_db_option_group.default.*.id)), 0)
}

output "rds_db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = element(split(",", join(",", aws_db_option_group.default.*.arn)), 0)
}


