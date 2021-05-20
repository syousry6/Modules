# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------

variable "account_assume_role_name" {
  type    = string
  default = "OrganizationAccountAccessRole"
}

provider "aws" {
  version = "~> 2.26"
  region  = var.aws_region

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.account_id}:role/${var.account_assume_role_name}"
  # }
}

# Master Account

# variable "master_account_assume_role_name" {
#   type    = string
#   default = "grv-deployment-service"
# }

# provider "aws" {
#   alias   = "master"
#   version = "~> 2.26"
#   # version = "~> 2.26.0"
#   region = var.aws_region

#   assume_role {
#     role_arn = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
#   }
# }

# Shared Services

# variable "shared_account_assume_role_name" {
#   type    = string
#   default = "grv-deployment-service"
# }

# provider "aws" {
#   alias   = "shared"
#   version = "~> 2.26"
#   # version = "~> 2.26.0"
#   region  = var.aws_region

#   assume_role {
#     role_arn = "arn:aws:iam::${var.shared_account_id}:role/${var.shared_account_assume_role_name}"
#   }
# }
