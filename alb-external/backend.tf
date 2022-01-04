terraform {
  backend "s3" {
    encrypt = true
    bucket = "macewan-s3backend"
    dynamodb_table = "tf-remote-state-lock"
    region = "us-west-2"
    key = "us-west-2/alb-external/terraform.tfstate"
  }
}
