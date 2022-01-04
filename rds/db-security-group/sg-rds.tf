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

variable "rds_port" {
  type        = list
  default     = [""]
  description = "description"
}

variable "rds_name"{
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ingress_cidr_blocks" {
  type = list(string)
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  # name        = var.rds_name
  description = "allow all connection to oracle rds."
  vpc_id      = var.vpc_id

  tags =  merge(
    local.tags,
    {
    Name = var.rds_name
  })
}

resource "aws_security_group_rule" "rds_sg_ingress_rule" {
  count             = var.create ? length(compact(var.rds_port)) : 0
  type              = "ingress"
  from_port         = var.rds_port[count.index]
  to_port           = var.rds_port[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks
  security_group_id = aws_security_group.rds_sg[0].id
}
resource "aws_security_group_rule" "rds_sg_egress_rule" {
  count             = var.create ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg[0].id
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "sg_rds_id" {
  value = aws_security_group.rds_sg[0].id
}