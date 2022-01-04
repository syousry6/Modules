# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = module.alb-ext.alb_name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.alb-ext.alb_arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = module.alb-ext.alb_arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = module.alb-ext.alb_dns_name
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = module.alb-ext.alb_zone_id
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = module.alb-ext.*.security_group_ids
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = module.alb-ext.*.target_group_arns
}

output "http_listener_arns" {
  description = "The ARNs of the HTTP listeners"
  value       = module.alb-ext.*.http_listener_arns
}


 output "access_logs_bucket_id" {
   description = "The S3 bucket ID for access logs"
   value       = module.alb-ext.access_logs_bucket_id
 }

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = module.alb-ext.route53_dns_name
}