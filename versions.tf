terraform {
  required_version = "~> 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cohorts"
    workspaces {
      prefix = "twelve-lab-platform-eks-base-"
    }
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = local.authentication_role
    session_name = "twelve-lab-platform-eks-base"
  }

  default_tags {
    tags = {
      env      = var.cluster_name
      cluster  = var.cluster_name
      pipeline = "twelve-lab-platform-eks-base"
    }
  }
}

locals {
  authentication_role = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_assume_role}"
}
