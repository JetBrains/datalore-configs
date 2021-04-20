terraform {
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}
