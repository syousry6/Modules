# RDS Module

## Purpose of This Module

The purpose of this module is to create RDS instance in private subnets.

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
      key    = "us-west-2/vpc/terraform.tfstate"
      region = "us-west-2"
  }
}

data "terraform_remote_state" "db-security-group" {
  backend = "s3" 
  config  = {
      bucket = "macewan-s3backend"
      key = "us-west-2/rds/rds-groups/terraform.tfstate"
      region = "us-west-2"
  }
}

data "terraform_remote_state" "db-option-group" {
  backend = "s3" 
  config  = {
      bucket = "macewan-s3backend"
      key = "us-west-2/rds/rds-groups/terraform.tfstate"
      region = "us-west-2"
  }
}

data "terraform_remote_state" "db-parameter-group" {
  backend = "s3" 
  config  = {
      bucket = "macewan-s3backend"
      key = "us-west-2/rds/rds-groups/terraform.tfstate"
      region = "us-west-2"
  }
}


data "terraform_remote_state" "db-subnet-group" {
  backend = "s3" 
  config  = {
      bucket = "macewan-s3backend"
      key = "us-west-2/rds/rds-groups/terraform.tfstate"
      region = "us-west-2"
  }
}


module "db-instance" {
  source                  = "git::git@github.com:macewanu/onica-poc-modules.git//aws/db-instance?ref=v0.1.0"
  rds_name                = "rds-db-oracle-instance"
  rds_sg                  = data.terraform_remote_state.db-security-group.outputs.sg_rds_id
  db_subnet_group_name    = data.terraform_remote_state.db-subnet-group.outputs.rds_db_subnet_group_id
  option_group_name       = data.terraform_remote_state.db-option-group.outputs.rds_db_option_group_id
  parameter_group_name    = data.terraform_remote_state.db-parameter-group.outputs.rds_db_parameter_group_id
  allocated_storage       = "1000"
  rds_engine              = "oracle-se2"
  engine_version          = "12.2.0.1.ru-2021-07.rur-2021-07.r1"
  rds_instance_class      = "db.m5.xlarge"
  backup_retention_period = 1
  multi_az                = true
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "rds_id" {
  value = module.db-instance.rds_id
}

output "rds_address" {
  value = module.db-instance.rds_address
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
    key = "us-west-2/rds/db-instance/terraform.tfstate"
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


