terraform {
  backend "s3" {
    bucket         = "my-terraform-states-tolugit"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}