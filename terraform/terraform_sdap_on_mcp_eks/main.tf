terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    token = data.aws_eks_cluster_auth.this.token
  }
}

module "unity_eks" {
  source = "git@github.com:unity-sds/unity-cs-infra.git//terraform-unity-eks_module"
  tags = var.tags
  deployment_name = var.deployment_name
  nodegroups = var.nodegroups
  aws_auth_roles = var.aws_auth_roles
  project = var.project
  venue = var.venue
  installprefix = var.installprefix
}

module "deploy_spark_operator" {
  source = "./modules/deploy_spark_operator"
  depends_on = [module.unity_eks]
  eks_cluster_name = var.deployment_name
  aws_region = var.aws_region
  namespace = var.spark_operator_config["namespace"]
  helm_chart_version = var.spark_operator_config["helm_chart_version"]
  image_tag = var.spark_operator_config["image_tag"]
}
