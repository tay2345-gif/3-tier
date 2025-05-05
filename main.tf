provider "aws" {
  region = var.aws_region 
}

terraform {     #Backend
    cloud {
    organization = "the-best"
    workspaces {
      name = "3-tier"
    }
  }
}