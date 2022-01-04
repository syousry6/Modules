# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE / AMI definition
# ----------------------------------------------------------------------------------------------------------------------

data "aws_availability_zones" "available_az" {
}

variable "map_migrated" {
  type        = list
  default     = [""]
  description = "description"
}

variable "aws_migration_project_id" {
  type        = string
  default     = "MPE26978"
  description = ""
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnet_ids" {
  type = list(string)
}

locals {
  vpc_subnet_ids = flatten(var.vpc_subnet_ids)
  availability_zone = "${var.aws_region}a"
}

# PUM machine
variable "vm_dc_instance_type" {
  description = "EC2 instance type"
  default     = "t2.large"
  type        = string
}

variable "vm_dc_disk_size" {
  description = "EC2 root disk size"
  default     = "150"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to launch"
  type        = number
  default     = 2
}

variable "ebs_count" {
  description = "Number of instances to launch"
  type        = number
  default     = 2
}

variable "placement_group" {
  description = "The Placement Group to start the instance in"
  type        = string
  default     = ""
}

variable "get_password_data" {
  description = "If true, wait for password data to become available and retrieve it."
  type        = bool
  default     = false
}

variable "tenancy" {
  description = "The tenancy of the instance (if the instance is running in a VPC). Available values: default, dedicated, host."
  type        = string
  default     = "default"
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#Using_ChangingInstanceInitiatedShutdownBehavior
  type        = string
  default     = ""
}



variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = ""
}


variable "associate_public_ip_address" {
  description = "If true, the EC2 instance will have associated public IP address"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address to associate with the instance in a VPC"
  type        = string
  default     = null
}


variable "private_ips" {
  description = "A list of private IP address to associate with the instance in a VPC. Should match the number of instances."
  type    = list(string)
  default = [""]
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs."
  type        = bool
  default     = true
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data directly. Use this instead of user_data whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
  type        = string
  default     = ""
}

variable "ipv6_address_count" {
  description = "A number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet."
  type        = number
  default     = null
}



variable "ipv6_addresses" {
  description = "Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface"
  type        = list(string)
  default     = null
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the devices created by the instance at launch time"
  type        = map(string)
  default     = {}
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance. See Block Devices below for details"
  type        = list(map(string))
  default     = []
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(map(string))
  default     = []
}

variable "ephemeral_block_device" {
  description = "Customize Ephemeral (also known as Instance Store) volumes on the instance"
  type        = list(map(string))
  default     = []
}

variable "network_interface" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(map(string))
  default     = []
}

variable "cpu_credits" {
  description = "The credit option for CPU usage (unlimited or standard)"
  type        = string
  default     = "standard"
}

variable "metadata_options" {
  description = "Customize the metadata options of the instance"
  type        = map(string)
  default     = {}
}

variable "use_num_suffix" {
  description = "Always append numerical suffix to instance name, even if instance_count is 1"
  type        = bool
  default     = false
}

variable "num_suffix_format" {
  description = "Numerical suffix format used as the volume and EC2 instance name suffix"
  type        = string
  default     = "-%d"
}


data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}


#########################################################
# AMI Definition.
#########################################################

data "aws_ami" "linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["RHEL_HA-8.4.0_HVM-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["309956199498"] # Canonical
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

#########################################################
# Security group for AD writer. All traffic from my IP.
#########################################################

variable ingress_cidrs {
  type        = list(string)
  default     = [""]
  description = "description"
}


variable secondary_ingress_cidrs {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable ec2_udp_allowed_ports {
  type        = list
  default     = [""]
  description = "description"
}

variable ec2_tcp_allowed_ports {
  type        = list
  default     = [""]
  description = "description"
}

# Security group
resource "aws_security_group" "default" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  vpc_id = var.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "allow_ingress_cidr_tcp" {
  count             = var.create ? length(compact(var.ec2_tcp_allowed_ports)) : 0
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = var.ec2_tcp_allowed_ports[count.index]
  to_port           = var.ec2_tcp_allowed_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp" {
  count             = var.create ? length(compact(var.ec2_udp_allowed_ports)) : 0
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = var.ec2_udp_allowed_ports[count.index]
  to_port           = var.ec2_udp_allowed_ports[count.index]
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_icmp" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "icmp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_egress" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.default[0].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


# secondry sg

# resource "aws_security_group" "secondary" {
#   count = var.create ? 1 : 0
#   name  = join("-", [local.module_prefix, "secondary"])

#   vpc_id = var.vpc_id

#   tags = merge(local.tags,map(
#     "map-migrated", "",
#   ))
# }

# resource "aws_security_group_rule" "allow_ingress_cidr_tcp_secondary" {
#   count             = var.create ? length(compact(var.ec2_tcp_allowed_ports)) : 0
#   security_group_id = aws_security_group.secondary[0].id
#   type              = "ingress"
#   from_port         = var.ec2_tcp_allowed_ports[count.index]
#   to_port           = var.ec2_tcp_allowed_ports[count.index]
#   protocol          = "tcp"
#   cidr_blocks       = var.secondary_ingress_cidrs
# }

# resource "aws_security_group_rule" "allow_ingress_cidr_udp_secondary" {
#   count             = var.create ? length(compact(var.ec2_udp_allowed_ports)) : 0
#   security_group_id = aws_security_group.secondary[0].id
#   type              = "ingress"
#   from_port         = var.ec2_udp_allowed_ports[count.index]
#   to_port           = var.ec2_udp_allowed_ports[count.index]
#   protocol          = "udp"
#   cidr_blocks       = var.secondary_ingress_cidrs
# }

# resource "aws_security_group_rule" "allow_ingress_cidr_icmp_secondary" {
#   count             = var.create ? 1 : 0
#   security_group_id = aws_security_group.secondary[0].id
#   type              = "ingress"
#   from_port         = "-1"
#   to_port           = "-1"
#   protocol          = "icmp"
#   cidr_blocks       = var.secondary_ingress_cidrs
# }

# resource "aws_security_group_rule" "allow_egres_secondary" {
#   count             = var.create ? 1 : 0
#   security_group_id = aws_security_group.secondary[0].id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }


#########################################################
# IAM policies for joining domain
#########################################################


# resource "aws_iam_role_policy_attachment" "ec2-ad-role-policy-attach" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
# }


resource "aws_iam_role" "ec2_ssm_role" {
  name               = join("-", [local.module_prefix, "ec2-ssm-role"])
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm-instance" {
  role       = aws_iam_role.ec2_ssm_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm-ad" {
  role       = aws_iam_role.ec2_ssm_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}


resource "aws_iam_instance_profile" "ec2_ssm_role_profile" {
  name    = join("-", [local.module_prefix, "ec2-ssm-role-profile"])
  role    = aws_iam_role.ec2_ssm_role.name
}


# resource "aws_ssm_document" "ssm_document" {
#   name          = "ssm_document_example.com"
#   document_type = "Command"
#   content       = <<DOC
# {
#     "schemaVersion": "1.0",
#     "description": "Automatic Domain Join Configuration",
#     "runtimeConfig": {
#         "aws:domainJoin": {
#             "properties": {
#                 "directoryId": "d-9a672c0b17",
#                 "directoryName": "ds.macewan.cloud",
#                 "dnsIpAddresses": [
#                      "10.50.10.43",
#                      "10.50.20.21"
#                   ]
#             }
#         }
#     }
# }
# DOC
# }

# resource "aws_ssm_association" "associate_ssm" {
#   name        = aws_ssm_document.ssm_document.name
#   instance_id = aws_instance.ec2_instance[0].id
# }
#########################################################
# EC2 Module.
#########################################################

resource "aws_instance" "instance" {
  count                  = var.create ? var.instance_count : 0
  ami                    = data.aws_ami.linux.id
  instance_type          = var.vm_dc_instance_type
  subnet_id              = element(var.vpc_subnet_ids, count.index)
  key_name               = var.key_name
  monitoring             = var.monitoring
  get_password_data      = var.get_password_data
  vpc_security_group_ids = [
    "${aws_security_group.default[0].id}"
  ]
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_ssm_role_profile.name}"
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = "${element(var.private_ips, count.index)}"
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses
  ebs_optimized               = var.ebs_optimized

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(keys(var.metadata_options)) == 0 ? [] : [var.metadata_options]
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", "enabled")
      http_tokens                 = lookup(metadata_options.value, "http_tokens", "optional")
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", "1")
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  # placement_group                      = var.placement_group
  tenancy = var.tenancy

  tags = merge(
    local.tags,
    tomap({
      "Name" = join("-", [local.module_prefix, count.index + 1]),
      "map-migrated" = element(var.map_migrated, count.index),
    })
  )

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}


#########################################################
# For EBS attachment.
#########################################################
resource "aws_volume_attachment" "default" {
  count         = var.create ? var.ebs_count : 0
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.default[count.index].id
  instance_id = aws_instance.instance[count.index].id
}

resource "aws_ebs_volume" "default" {
  count         = var.create ? var.ebs_count : 0
  availability_zone = data.aws_availability_zones.available_az.names[count.index]
  size              = 250

  tags = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "dc_instances" {
  description = "List the info for dc instances"
  value       = aws_instance.instance.*
}

