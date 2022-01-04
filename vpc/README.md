
# VPC Module

## Purpose of This Module

The purpose of this module is to create vpc instance.


## Dependency 
### This module has a few dependencies:
1. Terraform version 1.0.0

## How to Use This Module

Create a new Terraform project and a `main.tf` with the following:

```hcl
module "vpc_module" {
  source             = "git::git@github.com:macewanu/onica-poc-modules.git//aws/vpc?ref=v0.1.0"
  azs                = ["us-west-2"]
  vpc_name           = "opspoc-vpc"
  vpc_cidr_block     = "10.64.96.0/20"
  private_subnets    = ["10.64.96.0/24", "10.64.97.0/24"]
  public_subnets     = ["10.64.110.0/24", "10.64.111.0/24"]
  enable_nat_gateway = true
}

## Output
# VPC
output "vpc_id" {
  value = module.vpc_module.vpc_id
}
output "vpc_cidr_block" {
  value = module.vpc_module.vpc_cidr_block
}


# Subents
output "subnet_public_id" {
  value = module.vpc_module.subnet_public_id
}
output "subnet_priv_id" {
  value = module.vpc_module.subnet_priv_id
}


# Route Tables
output "route_table_public" {
  value = module.vpc_module.route_table_public
}

output "route_table_private" {
  value = module.vpc_module.route_table_private
}



# Private



output "vpc_key_pair_private_name" {
  description = "Name of the private SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_private_name : null

}

output "vpc_key_pair_private_pem" {
  description = "Private SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_private_pem : null
  sensitive   = true
}


output "vpc_key_pair_private_pub" {
  description = "Public SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_private_pub : null
  sensitive   = true
}



# Public

output "vpc_key_pair_public_name" {
  description = "Name of the private SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_public_name : null
}

output "vpc_key_pair_public_pem" {
  description = "Private SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_public_pem : null
  sensitive   = true
}


output "vpc_key_pair_public_pub" {
  description = "Public SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.vpc_module.vpc_key_pair_public_pub : null
  sensitive   = true
}

```


Create a `backend.tf`, for example:

```hcl
terraform {
  
  backend "s3" {
    encrypt = true
    bucket = "macewan-s3backend"
    dynamodb_table = "tf-remote-state-lock"
    region = "us-west-2"
    key = "us-west-2/vpc/terraform.tfstate"
  }
}
```


Create a `module.tf` with all generic variables

```hcl
# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "vpc"
  description = "The name of the module"
}

variable terraform_module {
  type        = string
  default     = "macewan/onica-poc-modules/aws/vpc"
  description = "The owner and name of the Terraform module"
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "The AWS region to deploy module into"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

# Recommended

variable "namespace" {
  type        = string
  default     = "macewan"
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. HashiCorp 'hc')"
}

variable "environment" {
  type        = string
  default     = ""
  description = "The isolated environment the module is associated with (e.g. Master Services `Master`, Application `app`)"
}

variable "stage" {
  type        = string
  default     = "non-prd"
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "repository" {
  type        = string
  default     = ""
  description = "The repository where the code referencing the module is stored"
}

variable "account_id" {
  type        = string
  default     = "907193732944"
  description = "The AWS Account ID that contains the calling entity"
}

variable "master_account_id" {
  type        = string
  default     = ""
  description = "The Master AWS Account ID that owns the associate AWS account"
}

# Optional

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional map of tags (e.g. business_unit, cost_center)"
}

variable "desc_prefix" {
  type        = string
  default     = "macewan:"
  description = "The prefix to add to any descriptions attached to resources"
}

variable "environment_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace` and `environment`"
}

variable "stage_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment` and `stage`"
}

variable "module_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment`, `stage` and `name`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

# Derived

data "aws_caller_identity" "current" {
  # count = var.account_id == "" ? 1 : 0
}

locals {
  account_id = var.account_id == "" ? data.aws_caller_identity.current.account_id : var.account_id

  environment_prefix = coalesce(var.environment_prefix, join(var.delimiter, compact([var.namespace, var.environment])))
  stage_prefix       = coalesce(var.stage_prefix, join(var.delimiter, compact([local.environment_prefix, var.stage])))
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.name])))


  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage             = var.stage
    module            = var.name
    repository        = var.repository
    master_account_id = var.master_account_id
    account_id        = local.account_id
    aws_region        = var.aws_region
  }
  automation_tags = {
    # terraform_module = var.terraform_module
    stage_prefix     = local.stage_prefix
    module_prefix    = local.module_prefix
  }
  security_tags = {}

  # map_tags = {
  #   map-migrated             = var.map_migrated
  #   aws-migration-project-id = var.aws_migration_project_id
  # }

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    # local.map_tags,
    var.tags
  )
}
```


## Outputs

The following are outputs that are worth considering, though only the
`bucket_name` output is necessary for basic operations (the others are helpful
for more advanced use of this module, when exporting outputs to other projects
for example):

```hcl
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
# VPC
output "vpc_id" {
  value = aws_vpc.vpc[0].id
}
output "vpc_cidr_block" {
  value = aws_vpc.vpc[0].cidr_block
}

# Subents
output "subnet_public_id" {
  value = aws_subnet.public_subnets.*.id
}
output "subnet_priv_id" {
  value = aws_subnet.private_subnets.*.id
}
# Route Tables
output "route_table_public" {
  value = aws_route_table.pub_route.*.id
}
output "route_table_private" {
  value = aws_route_table.priv_route.*.id
}

```