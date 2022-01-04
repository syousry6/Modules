data "aws_iam_policy_document" "tf" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.terraform_state_s3.arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.terraform_state_s3.arn}/*"]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [aws_dynamodb_table.dynamodb_terraform_state_lock.arn]
  }
}

resource "aws_iam_policy" "tf" {
  name        = "terraform-state-${var.namespace}"
  description = "Policy for Terraform users to access the state and lock table"
  policy      = data.aws_iam_policy_document.tf.json
}