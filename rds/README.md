# RDS Module

## Purpose of This Module

The purpose of this module is to create RDS configuration option group, configuration parameter group, security group and subnet group.

## Dependency 
### This module has a few dependencies:
1. Terraform version 1.0.0
2. VPC module for vpc_id from (vpc_id) output.

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


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
module "sg-rds" {
  source = "git::git@github.com:macewanu/onica-poc-modules.git//aws/rds/db-security-group?ref=v0.1.0"
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress_cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  rds_port            = ["1521"]
  rds_name            = "rds-oracle-sg"
}

module "db-subnet-group" {
  source          = "git::git@github.com:macewanu/onica-poc-modules.git//aws/rds/db-subnet-group?ref=v0.1.0"
  subnet_ids      = data.terraform_remote_state.vpc.outputs.subnet_priv_id
}


module "db-parameter-group" {
  source = "git::git@github.com:macewanu/onica-poc-modules.git//aws/rds/db-parameter-group?ref=v0.1.0"
  family = "oracle-se2-12.2"
}

module "db-option-group" {
  source = "git::git@github.com:macewanu/onica-poc-modules.git//aws/rds/db-option-group?ref=v0.1.0"
  engine_version = "12.2.0.1.ru-2021-07.rur-2021-07.r1"
  major_engine_version = "12.2"   
  engine_name    = "oracle-se2"
}




# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Security Group outputs
# ----------------------------------------------------------------------------------------------------------------------

output "sg_rds_id" {
  value = module.sg-rds.sg_rds_id
}




# ----------------------------------------------------------------------------------------------------------------------
# Subnet Group outputs
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_subnet_group_id" {
  description = "The db subnet group name"
  value       = element(concat(module.db-subnet-group.*.rds_db_subnet_group_id, [""]), 0)
}

output "rds_db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = element(concat(module.db-subnet-group.*.rds_db_subnet_group_arn, [""]), 0)
}


# ----------------------------------------------------------------------------------------------------------------------
# Parameter Group outputs
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_parameter_group_id" {
  description = "The db parameter group id"
  value       = element(split(",", join(",", module.db-parameter-group.*.rds_db_parameter_group_id)), 0)
}

output "rds_db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = element(split(",", join(",", module.db-parameter-group.*.rds_db_parameter_group_arn)), 0)
}



# ----------------------------------------------------------------------------------------------------------------------
# Option Group outputs
# ----------------------------------------------------------------------------------------------------------------------

output "rds_db_option_group_id" {
  description = "The db option group id"
  value       = element(split(",", join(",", module.db-option-group.*.rds_db_option_group_id)), 0)
}

output "rds_db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = element(split(",", join(",", module.db-option-group.*.rds_db_option_group_arn)), 0)
}


```



Create a `backend.tf` and comment the code, for example:

```hcl

terraform {
  backend "s3" {
    encrypt = true
    bucket = "macewan-s3backend"
    dynamodb_table = "tf-remote-state-lock"
    region = "us-west-2"
    key = "us-west-2/rds/rds-groups/terraform.tfstate"
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


