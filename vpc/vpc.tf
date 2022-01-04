# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "map_migrated" {
  type        = string
  default     = "d-server-01h73qzcsagfqf"
  description = ""
}

variable "aws_migration_project_id" {
  type        = string
  default     = "MPE26978"
  description = ""
}


variable "vpc_cidr_block" {
}

variable "vpc_name" {
  type        = string
}

variable "public_subnets" {
    type        = list
    default = []
}

variable "private_subnets" {
    description = "A list of private subnets inside the VPC"
    type        = list
    default = []
}


variable "nat_gateways_count" {
  description = "It can be between 1 and the number of public subnets" 
  type    = string
  default = "2"
}


variable "elasticache_subnets" {
  description = "A list of elasticache subnets"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     = []
}

variable "redshift_subnets" {
  description = "A list of redshift subnets"
  type        = list(string)
  default     = []
}

variable "enable_public_subnets" {
  type    = string
  default = "true"
}

variable "route_priv_name" {
    type        = string
    default     = "private"
}

variable "az_count" {
  description = "the number of AZs to deploy infrastructure to"
  default     = 2
}


variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

# variable "create" {
#   description = "Controls if VPC should be created (it affects almost all resources)"
#   type        = bool
#   default     = true
# }

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}


variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  type        = bool
  default     = false
}


variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

variable "reuse_nat_ips" {
  description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'eip_nat_ip_ids' variable"
  type        = bool
  default     = true
}
variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "eip_nat_ip_ids" {
  description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
  type        = list(string)
  default     = []
}

# locals {
#   nat_gateway_ips = split(
#     ",",
#     var.reuse_nat_ips ? join(",", ${aws_eip.nat_ip.*.id}) : join(",", aws_eip.nat_ip.*.id),
#   )
# }

variable "nat_gateway_count" {
  type        = string
  default = "2"
}

locals {
  max_subnet_length = length(var.private_subnets)
  # nat_gateway_count = var.enable_nat_gateway ? min(length(var.azs), length(var.public_subnets), length(var.private_subnets)) : local.max_subnet_length
  # nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# VPC
resource "aws_vpc" "vpc"{
  count = var.create? 1 : 0
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = merge(
    local.tags,
    {
    Name = var.vpc_name
    })
}

## get az in the region
data "aws_availability_zones" "az" {
  state = "available"
}


## az in region
resource "aws_subnet" "public_subnets"{
    count             = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
    availability_zone = element(data.aws_availability_zones.az.names, count.index)
    vpc_id = aws_vpc.vpc[0].id
    cidr_block = element(var.public_subnets,count.index)
    tags = merge(
    local.tags,
    {
        Name = "${local.stage_prefix}-public-subnet-${count.index+1}"
    })

}



## private subnets
resource "aws_subnet" "private_subnets"{
    count = var.create&& length(var.private_subnets) > 0 ? length(var.private_subnets) : 0
    availability_zone = element(data.aws_availability_zones.az.names, count.index)
    vpc_id = aws_vpc.vpc[0].id
    cidr_block = element(var.private_subnets,count.index)
     tags = merge(
    local.tags,
    {
        Name = "${local.stage_prefix}-private-subnet-${count.index+1}" //prefix
    })

}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  count = var.create&& var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags = merge(
    local.tags,
    {
      Name = "${local.stage_prefix}-igw"
    }
  )
}

## EIP
resource "aws_eip" "nat_ip" {
  # count = var.create&& var.enable_nat_gateway && false == var.reuse_nat_ips ? var.nat_gateway_count : 0
  count = "${var.nat_gateways_count}"
  vpc    = true 
}

# Nat Gateway

resource "aws_nat_gateway" "ngw" {
  count         = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)
  allocation_id = element(aws_eip.nat_ip.*.id, count.index)
  # allocation_id = aws_eip.nat_ip.*.id
  tags = merge(
    local.tags,
    {
      Name = "${local.stage_prefix}-ngw-${count.index+1}"
    }
  )
}

# Public Route Tables
resource "aws_route_table" "pub_route" {
  count = var.create&& length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags = merge(
    local.tags,
    {
      Name = "${local.stage_prefix}-public_RT"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create&& var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.pub_route[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id

  timeouts {
    create = "5m"
  }
}


# Private Route Table
resource "aws_route_table" "priv_route" {
  count = var.create&& local.max_subnet_length > 0 ? var.nat_gateway_count : 0
  vpc_id = aws_vpc.vpc[0].id
  tags = merge(
    local.tags,
    {
      Name = "${local.stage_prefix}-private_RT-${count.index+1}"
    }
  )
}

## Public Routing associations
resource "aws_route_table_association" "pub_route_association" {
  count = var.create&& length(var.public_subnets) > 0 ? length(var.public_subnets) : 0
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.pub_route[0].id
}


## Private Routing associations
resource "aws_route_table_association" "private_route" {
  count = var.create&& length(var.private_subnets) > 0 ? length(var.private_subnets) : 0
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.priv_route[0].id
}


resource "aws_route" "private_nat_gateway" {
  count                  = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  route_table_id         = element(aws_route_table.priv_route.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
}


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

