terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "unity_eks" {
  source = "./terraform_unity_eks_module"
  tags = var.tags
  deployment_name = var.deployment_name
  nodegroups = var.nodegroups
  aws_auth_roles = var.aws_auth_roles
  project = var.project
  venue = var.venue
  installprefix = var.installprefix
}
