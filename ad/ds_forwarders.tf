# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "ds_forwarders" {
  type        = map(list(string))
  default     = {}
  description = "Map of DNS conditional forwarders"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# directory_id - (Required) The id of directory.
# dns_ips - (Required) A list of forwarder IP addresses.
# remote_domain_name - (Required) The fully qualified domain name of the remote domain for which forwarders will be used.
resource "aws_directory_service_conditional_forwarder" "ds_forwarders" {
  for_each = var.create ? var.ds_forwarders : {}

  directory_id       = aws_directory_service_directory.ds[0].id
  remote_domain_name = each.key
  dns_ips            = each.value
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ds_conditional_forwarders" {
  description = "Map of conditional forwards"
  value       = aws_directory_service_conditional_forwarder.ds_forwarders
}
