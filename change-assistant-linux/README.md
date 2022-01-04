

# PUM Module

## Purpose of This Module

The purpose of this module is to create EC2 linux instances for Change Assistant.


## Dependency 
### This module has a few dependencies:
1. Terraform version 1.0.0
2. VPC module for vpc_id, vpc_subnet_ids and key_name from (vpc_id, vpc_key_pair_private_name, vpc_key_pair_private_name) outputs.




## How to Use This Module

Create a new Terraform project and a `main.tf` with the following:

```hcl

data "terraform_remote_state" "vpc" {
  backend = "s3" 
  config  = {
      bucket = "macewan-s3backend"
      key = "us-west-2/vpc/terraform.tfstate"
      region = "us-west-2"
  }
}

module "change-assistant-linux" {
  source                      = "git::git@github.com:macewanu/onica-poc-modules.git//aws/change-assistant-linux?ref=v0.1.0"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_subnet_ids              = data.terraform_remote_state.vpc.outputs.subnet_priv_id
  key_name                    = data.terraform_remote_state.vpc.outputs.vpc_key_pair_private_name
  map_migrated                = ["d-server-01h73qzcsagfqf"]
  private_ips                 = [""]
  ec2_tcp_allowed_ports       = ["22"]
  ec2_udp_allowed_ports       = [""]
  ingress_cidrs = ["10.64.96.0/20"]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "dc_instances" {
  description = "List the info for dc instances"
  value       = module.change-assistant-linux.*
}

```


Create/Use a `backend.tf` , for example:

```hcl
terraform {
  
  backend "s3" {
    encrypt = true
    bucket = "macewan-s3backend"
    dynamodb_table = "tf-remote-state-lock"
    region = "us-west-2"
    key = "us-west-2/change-assistant-linux/terraform.tfstate"
  }
}
```


Use the following `providers.tf`:

```hcl

# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.0.0"
}

provider "aws" {
  version = ">= 3.64.0"
  region  = "us-west-2"
}


```


Create a `module.tf` with all generic variables

```hcl
# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "change-assistant-linux"
  description = "The name of the module"
}

variable terraform_module {
  type        = string
  default     = "macewan/onica-poc-modules/aws/change-assistant-linux"
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

```hcl
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "dc_instances" {
  description = "List the info for dc instances"
  value       = aws_instance.instance.*
}

```


