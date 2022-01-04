# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "map_migrated" {
  type        = string
  default     = "d-server-01h73qzcsagfqf"
  description = ""
}

variable "map_migrated_app" {
  type        = string
  default     = "backend"
  description = ""
}

variable "aws_migration_project_id" {
  type        = string
  default     = "MPE26978"
  description = ""
}

variable "bucket_name" {
  description = "Bucket name for the S3 bucket to store state files"
  default     = ""
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for locking state files"
  default     = ""
}

variable "principals" {
  description = "list of user/role ARNs to get full access to the bucket"
  type        = list(string)
}

# variable "cross_account_user_arn"{
#   type        = string
#   description = ""
#   default     = "arn:aws:iam:::user/terraform-code-user"
# }

locals {
  default_bucket_name         = "terraform_state_s3-${data.aws_caller_identity.current.account_id}"
  default_dynamodb_table_name = "terraform-state-lock-${data.aws_caller_identity.current.account_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "terraform_state_s3" {
  bucket = var.bucket_name == "" ? local.default_bucket_name : var.bucket_name
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
  lifecycle_rule {
    id                                     = "AutoAbortFailedMultipartUpload"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 10
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}



resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.terraform_state_s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3-full-access" {
  bucket = aws_s3_bucket.terraform_state_s3.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "PutObjPolicy",
  "Statement": [
    {
      "Sid": "DenyIncorrectEncryptionHeader",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.terraform_state_s3.arn}/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.terraform_state_s3.arn}/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption": "true"
        }
      }
    }
  ]
}
EOF

  depends_on = [aws_s3_bucket_public_access_block.default]
}

resource "aws_dynamodb_table" "dynamodb_terraform_state_lock" {
  name         = var.dynamodb_table_name == "" ? local.default_dynamodb_table_name : var.dynamodb_table_name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
  depends_on = [aws_s3_bucket.terraform_state_s3]
}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "bucket_id" {
  value       = aws_s3_bucket.terraform_state_s3.id
  description = "Id (name) of the S3 bucket"
}

output "locktable_id" {
  value       = aws_dynamodb_table.dynamodb_terraform_state_lock.id
  description = "Id (name) of the DynamoDB lock table"
}

output "tf_policy_name" {
  value       = aws_iam_policy.tf.name
  description = "The name of the policy for Terraform users to access the state and lock table"
}

output "tf_policy_arn" {
  value       = aws_iam_policy.tf.arn
  description = "The ARN of the policy for Terraform users to access the state and lock table"
}

output "tf_policy_id" {
  value       = aws_iam_policy.tf.id
  description = "The ID of the policy for Terraform users to access the state and lock table"
}