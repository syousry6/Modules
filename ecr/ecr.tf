# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "ecr_name" {
  type        = string
  default     = "peoplesoft_me"
  description = "Elastic container repository name."
}



# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "PeopleSoft-me" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"



  image_scanning_configuration {
    scan_on_push = true
  }

  tags  = local.tags

}


#### aws_ecr_repository_policy can be attached to container repository to apply permissions for any IAM user or service needs that (codepipline, eks cluster, developer account. ...etc) .
# resource "aws_ecr_repository_policy" "PeopleSoft-me-policy" {
#   repository = aws_ecr_repository.PeopleSoft-me.name

#   policy = <<EOF
# {
#     "Version": "2008-10-17",
#     "Statement": [
#         {
#             "Sid": "new policy",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": [
#                 "ecr:GetDownloadUrlForLayer",
#                 "ecr:BatchGetImage",
#                 "ecr:BatchCheckLayerAvailability",
#                 "ecr:PutImage",
#                 "ecr:InitiateLayerUpload",
#                 "ecr:UploadLayerPart",
#                 "ecr:CompleteLayerUpload",
#                 "ecr:DescribeRepositories",
#                 "ecr:GetRepositoryPolicy",
#                 "ecr:ListImages",
#                 "ecr:DeleteRepository",
#                 "ecr:BatchDeleteImage",
#                 "ecr:SetRepositoryPolicy",
#                 "ecr:DeleteRepositoryPolicy"
#             ]
#         }
#     ]
# }
# EOF
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "registry_id" {
  description = "The account ID of the registry holding the repository."
  value = aws_ecr_repository.PeopleSoft-me.registry_id
}


output "repository_url" {
  description = "The URL of the repository."
  value = aws_ecr_repository.PeopleSoft-me.repository_url
}