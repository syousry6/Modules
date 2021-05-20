# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that supports locking and enforces best
# practices: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  #  source = "..//ec2"
  # source = "../../../terraform-gravicore-modules/aws//ec2"
  # source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/ec2?ref="
}

# Include all settings from the root terraform.tfvars file
include {
  path = find_in_parent_folders()
}

# dependencies {
#   paths = ["../account"]
# }

dependency "vpc" {
  config_path = "../../vpc"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  ec2_tcp_allowed_ports    = ["3389", "9389", "53", "464", "88", "389", "3268", "445", "636", "3269"]
  ec2_udp_allowed_ports    = ["53", "464", "88", "389", "138", "445", "123"]
  vpc_id                   = dependency.vpc.outputs.vpc_id
  vpc_subnet_ids           = dependency.vpc.outputs.vpc_private_subnets
  key_name                 = dependency.vpc.outputs.vpc_key_pair_private_name
  map_migrated             = ["d-server-01l3aw77ewj7ba", "d-server-01om4rh1ftodxs"]
  map_migrated_app         = "AD Mgmnt"
  aws_migration_project_id = "MPE09872"
  ingress_cidrs = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "192.178.30.0/23",
    "192.178.38.0/23",
    "192.178.70.0/23",
    "192.180.38.0/24",
    "192.181.38.0/24",
    "192.182.38.0/24",
    "192.183.15.0/24",
    "192.183.36.0/23",
  ]
}

