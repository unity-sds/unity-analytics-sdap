terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    token = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  token = data.aws_eks_cluster_auth.this.token
}

data "kubernetes_secret" "rabbitmq_secret" {
  metadata {
    name = "rabbitmq"
    namespace = var.namespace
  }
  binary_data = {
    "rabbitmq-erlang-cookie" = ""
    "rabbitmq-password" = ""
  }
}

resource "helm_release" "sdap_full" {
  upgrade_install = true
  name = "sdap"
  version = 1.0
  chart = "../../../../helm"
  namespace = var.namespace
  values = [
    "${file("../../../../k8s_deployment/values/values_noingest.yaml")}"
  ]
  set {
    name = "rabbitmq.auth.erlangCookie"
    value = base64decode(data.kubernetes_secret.rabbitmq_secret.binary_data.rabbitmq-erlang-cookie)
  }
}
