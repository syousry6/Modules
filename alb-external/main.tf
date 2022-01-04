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
  source              = "./module"
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids          = data.terraform_remote_state.vpc.outputs.subnet_public_id
  dns_zone_id         = data.terraform_remote_state.dns.outputs.dns_public_zone_id
  dns_zone_name       = data.terraform_remote_state.dns.outputs.dns_public_zone_name
  certificate_arn     = data.terraform_remote_state.acm.outputs.acm_certificate_arn
  access_logs_region  = "us-west-2"
  domain_name         = "ext"
# VPC CIDR Range
  http_ingress_cidr_blocks =  ["0.0.0.0/0"]
  https_ingress_cidr_blocks = ["0.0.0.0/0"]
}