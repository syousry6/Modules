# Remote State on S3

## Purpose of This Module

The purpose of this module is to create a remote backend to store Terraform deployment state in an S3 bucket. The module:

* creates the S3 bucket with versioning enabled
* creates an IAM policy that has full access to the bucket

## How to Use This Module

The use of this module has two stages. In the first stage we use a wrapper project to create the S3 bucket with appropriate policies. In the second stage we configure and initialize the remote backend. At the end of that process the state will be copied over to the remote backend and be available for other people to use as well.

### New Project

Create a new Terraform project and a `main.tf` with the following:

```hcl
module "s3-backend" {
  source              = "git::git@github.com:macewanu/onica-poc-modules.git//aws/tfstate-backend?ref=v0.1.0"
  bucket_name         = "macewan-s3backend"
  dynamodb_table_name = "tf-remote-state-lock"
  principals          = ["*"]
}

```



Create a `backend.tf` and comment the code, for example:

```hcl
#terraform {
#  backend "s3" {
#    encrypt = true
#    bucket = "macewan-s3backend"
#    dynamodb_table = "tf-remote-state-lock"
#    region = "us-west-2"
#    key = "us-west-2/tfstate-backend/terraform.tfstate"
#  }
#}


```


Create a `module.tf` with all generic variables

```hcl
# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "tfstate-backend"
  description = "The name of the module"
}

variable terraform_module {
  type        = string
  default     = "macewan/onica-poc-modules/aws/tfstate-backend"
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

Then the `IAM` policies and `S3` bucket using Terraform.


### Initialize the Remote State S3 Backend

We want to use the newly created S3 bucket to store the Terraform state for this module. There are several steps that need to be taken. Make sure to backup your existing `terraform.tfstate` file before taking these steps:

1. First we have to [initialize the backend][1] and copy over the current state of the backend bucket you just created. Uncomment the following, so that the code in the `main.tf` file looks similar to this:

```hcl
terraform {
  backend "s3" {
    encrypt = true
    bucket = "macewan-s3backend"
    dynamodb_table = "tf-remote-state-lock"
    region = "us-west-2"
    key = "us-west-2/tfstate-backend/terraform.tfstate"
  }
}
```

2. Now run the command `terraform init`.  You will get dialog similar to what you see in what follows. Where you are prompted with ** Enter a value:**, you should enter *yes*.

```hcl
Initializing modules...
- module.tfstate-backend

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 1.26"

Terraform has been successfully initialized!
```

3. Now that the initial configuration is done and we have copied over the state, we can permanently configure any other wrapper module to make use of the remote state. You can do this by copying the full configuration noted in step 1. This will ensure that anyone else who  will be using the existing configuration found in the S3 backend, once they run `terraform init`.



## Outputs

The following are outputs that are worth considering, though only the
`bucket_name` output is necessary for basic operations (the others are helpful
for more advanced use of this module, when exporting outputs to other projects
for example):

```hcl
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
```

## Deleting the state and buckets

If for any reason you no longer need this state and bucket, you can delete it as follows:

1. re-comment the `terraform` section with the remote state description and rerun `terrform init`. This will prompt with a question whether you want to copy back the remote state to local. Answer *yes*.
2. Manually delete the contents of the `S3` bucket
3. Run `terraform destroy`

