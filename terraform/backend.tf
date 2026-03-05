 terraform {
  backend "s3" {
    bucket         = "gyan-tf-state-ecommerce"
    key            = "ecommerce/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
