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
  source = "git@github.com:unity-sds/unity-cs-infra.git//terraform-unity-eks_module?ref=unity-sps-2.1.0"
  tags = var.tags
  deployment_name = var.deployment_name
  nodegroups = var.nodegroups
  aws_auth_roles = var.aws_auth_roles
  project = var.project
  venue = var.venue
  installprefix = var.installprefix
}
