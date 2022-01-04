
# AWS Application Load Balancer Terraform module

## Purpose of This Module

The purpose of this module is to create Application Load Balancer resources on AWS (External with HTTPs).


## Dependency 
### This module has a few dependencies:
1. Terraform version 1.0.0
2. VPC, ACM & DNS modules for vpc_id, subnet_ids, certificate_arn, dns_zone_id & dns_zone_name outputs.


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
data "terraform_remote_state" "dns" {
  backend = "s3" 
  config  = {
      bucket  = "macewan-s3backend"
      key     = "us-west-2/dns/terraform.tfstate"
      region  = "us-west-2"
  }
}



data "terraform_remote_state" "acm" {
  backend = "s3" 
  config  = {
      bucket  = "macewan-s3backend"
      key     = "us-west-2/acm/terraform.tfstate"
      region  = "us-west-2"
  }
}

module "alb-ext" {
  source                    = "git::git@github.com:macewanu/onica-poc-modules.git//aws/alb-external?ref=v0.1.0"
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids                = data.terraform_remote_state.vpc.outputs.subnet_public_id
  dns_zone_id               = data.terraform_remote_state.dns.outputs.dns_public_zone_id
  dns_zone_name             = data.terraform_remote_state.dns.outputs.dns_public_zone_name
  certificate_arn           = data.terraform_remote_state.acm.outputs.acm_certificate_arn
  access_logs_region        = "us-west-2"
  domain_name               = "ext"
# VPC CIDR Range
  http_ingress_cidr_blocks  =  ["0.0.0.0/0"]
  https_ingress_cidr_blocks = ["0.0.0.0/0"]
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = module.alb-ext.alb_name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.alb-ext.alb_arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = module.alb-ext.alb_arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = module.alb-ext.alb_dns_name
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = module.alb-ext.alb_zone_id
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = module.alb-ext.*.security_group_ids
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = module.alb-ext.*.target_group_arns
}

output "http_listener_arns" {
  description = "The ARNs of the HTTP listeners"
  value       = module.alb-ext.*.http_listener_arns
}


 output "access_logs_bucket_id" {
   description = "The S3 bucket ID for access logs"
   value       = module.alb-ext.access_logs_bucket_id
 }

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = module.alb-ext.route53_dns_name
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
    key = "us-west-2/alb-external/terraform.tfstate"
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
  default     = "alb"
  description = "The name of the module"
}

variable terraform_module {
  type        = string
  default     = "macewan/onica-poc-modules/aws/alb"
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
  count = var.account_id == "" ? 1 : 0
}

locals {
  account_id = var.account_id == "" ? data.aws_caller_identity.current[0].account_id : var.account_id

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
    terraform_module = var.terraform_module
    stage_prefix     = local.stage_prefix
    module_prefix    = local.module_prefix
  }
  security_tags = {}

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )
}


```


## Outputs


```hcl
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = aws_lb.alb[0].name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.alb[0].arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = aws_lb.alb[0].arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.alb[0].dns_name
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = aws_lb.alb[0].zone_id
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = aws_security_group.alb.*.id
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = aws_lb_target_group.alb.*.arn
}

output "http_listener_arns" {
  description = "The ARNs of the HTTP listeners"
  value       = aws_lb_listener.http.*.arn
}

 output "https_listener_arns" {
   description = "The ARNs of the HTTPS listeners"
   value       = aws_lb_listener.https.*.arn
 }

 output "listener_arns" {
   description = "A list of all the listener ARNs"
   value = compact(
     concat(aws_lb_listener.http.*.arn, aws_lb_listener.https.*.arn),
   )
 }

 output "access_logs_bucket_id" {
   description = "The S3 bucket ID for access logs"
   value       = module.access_logs.bucket_id
 }

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = aws_route53_record.alb[*].name
}
```


