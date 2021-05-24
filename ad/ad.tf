# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "map_migrated" {
  type        = string
  default     = ""
  description = ""
}

variable "map_migrated_app" {
  type        = string
  default     = ""
  description = ""
}

variable "aws_migration_project_id" {
  type        = string
  default     = ""
  description = ""
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

variable "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "parent_domain_name" {
  type = string
}

variable "aws_subdomain_name" {
  type    = string
  default = "aws"
}

variable "ds_subdomain_name" {
  type    = string
  default = "ds"
}

variable "ds_short_name" {
  type = string
}

variable "ds_edition" {
  description = "The MicrosoftAD edition (Standard or Enterprise)."
  default     = "Standard"
}

variable "parameter_store_kms_arn" {
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
  type        = string
  default     = "alias/parameter_store_key"
}

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

variable "enable_sso" {
  type    = bool
  default = false
}

locals {
  ds_alias           = replace("${var.namespace}-${var.ds_subdomain_name}-${var.stage}", "-prd", "")
  vpc_subdomain_name = replace("${var.stage}.${var.environment}", "prd.", "")
  ds_zone_name       = replace("${var.stage}.${var.ds_subdomain_name}.${var.parent_domain_name}", "prd.", "")
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "random_password" "ds_password" {
  count = var.create ? 1 : 0

  length      = 16
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  min_special = 4
  # override_special = "/@\" "
}

resource "aws_ssm_parameter" "ds_password" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-password"
  description = "Master Microsoft AD Directory Service Password"
  tags        = local.tags

  type = "SecureString"
  # key_id          = "${length(aws_kms_key.parameter_store_key.key_id) > 0 ? var.parameter_store_kms_arn : ""}"
  key_id    = coalesce(data.aws_kms_key.parameter_store_key.key_id, var.parameter_store_kms_arn, "")
  value     = random_password.ds_password[0].result
  overwrite = true
}

# name - (Required) The fully qualified name for the directory, such as corp.example.com
# password - (Required) The password for the directory administrator or connector user.
# vpc_settings - (Required for SimpleAD and MicrosoftAD) VPC related information about the directory. Fields documented below.
#     subnet_ids - (Required) The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs).
#     vpc_id - (Required) The identifier of the VPC that the directory is in.
resource "aws_directory_service_directory" "ds" {
  count = var.create ? 1 : 0
  name  = local.ds_zone_name
  tags  = local.tags

  type     = "MicrosoftAD"
  password = random_password.ds_password[0].result

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.vpc_private_subnets
    # subnet_ids = flatten([var.vpc_private_subnets])
  }

  alias       = local.ds_alias
  short_name  = var.ds_short_name
  description = join(" ", list(var.desc_prefix, "Master Microsoft AD Directory Service"))
  enable_sso  = var.enable_sso
  edition     = var.ds_edition

  lifecycle {
    ignore_changes = [
      password,
    ]
  }
}

# DS CNAME on parent domain
# zone_id - (Required) The ID of the hosted zone to contain this record.
# name - (Required) The name of the record.
# type - (Required) The record type. Valid values are A, AAAA, CAA, CNAME, MX, NAPTR, NS, PTR, SOA, SPF, SRV and TXT.
# ttl - (Required for non-alias records) The TTL of the record.
# records - (Required for non-alias records) A string list of records. To specify a single record value longer than 255 characters such as a TXT record for DKIM, add \"\" inside the Terraform configuration string (e.g. "first255characters\"\"morecharacters").
# resource "aws_route53_record" "aws" {
#   count = var.create ? 1 : 0

#   zone_id = aws_route53_zone.parent.zone_id
#   name    = "aws"
#   type    = "CNAME"
#   ttl     = "30"
#   records = ["${local.ds_alias}.awsapps.com"]
# }

# Allow Directory Services to login to console

data "aws_iam_policy_document" "ds" {
  count = var.create ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ds.amazonaws.com"]
    }
  }
}

# Administrator

resource "aws_iam_role" "ds_administrator" {
  count       = var.create ? 1 : 0
  name        = "${local.ds_alias}-administrator"
  description = join(" ", list(var.desc_prefix, "Directory Services AWS Delegated Administrator"))

  assume_role_policy = data.aws_iam_policy_document.ds[0].json
}

resource "aws_iam_role_policy_attachment" "ds_administrator" {
  count = var.create ? 1 : 0

  role       = aws_iam_role.ds_administrator[0].id
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ds_directory_id" {
  value = aws_directory_service_directory.ds[0].id
}

output "ds_access_url" {
  value = format("https://%s", aws_directory_service_directory.ds[0].access_url)
}

output "ds_access_console_url" {
  value = format("https://%s/console", aws_directory_service_directory.ds[0].access_url)
}

output "ds_dns_ip_addresses" {
  value = flatten(aws_directory_service_directory.ds[0].dns_ip_addresses)
}

output "ds_security_group_id" {
  value = aws_directory_service_directory.ds[0].security_group_id
}

output "ds_domain_name" {
  value = aws_directory_service_directory.ds[0].name
}
