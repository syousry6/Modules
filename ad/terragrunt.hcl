# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that supports locking and enforces best
# practices: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
}

# Include all settings from the root terraform.tfvars file
include {
  path = find_in_parent_folders()
}

# dependencies {
#   paths = ["../acct"]
# }

dependency "vpc" {
  config_path = "../../vpc"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  vpc_public_subnets  = dependency.vpc.outputs.vpc_public_subnets
  vpc_private_subnets = dependency.vpc.outputs.vpc_private_subnets
  map_migrated             = "d-server-01l3aw77ewj7ba"
  map_migrated_app         = "AD Mgmnt"
  aws_migration_project_id = "MPE09872"

#  ds_forwarders = {
#    "celink.com" = [
#      "192.168.38.100", "192.168.38.101", "192.168.38.102", # "192.168.30.101"
#      "192.168.39.101", "192.168.39.102",                   # "192.168.30.102", 
#    ],
#  }
}
