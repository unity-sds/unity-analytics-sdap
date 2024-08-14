# This terraform deploys the Kubeflow Kubernetes operator for Apache Spark
# on a configured Kubernetes cluster.
#
# Prerequisites:
# 1) The deployment host must have Kubernetes and Helm installed
# 2) Configure a Kubernetes cluster to use.  For AWS/EKS clusters:
#    > aws eks update-kubeconfig --name ${cluster_name}
#                                --region ${cluster_region}
#    You should then have a valid configuration in ~/.kube/config
# 3) Add the Kubeflow spark-operator helm repo:
#    > helm repo add spark-operator https://kubeflow.github.io/spark-operator
# 4) Deploy the spark-operator with Terraform
#    > terraform init
#    > terraform plan
#    > terraform apply

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

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    token = data.aws_eks_cluster_auth.this.token
  }
}

resource "helm_release" "spark-operator" {
  name = "spark-operator"
  chart = "spark-operator/spark-operator"
  atomic = true
  cleanup_on_fail = true
  create_namespace = true
  dependency_update = true
  namespace = var.namespace
  timeout = 60

  # As of August 2024, the helm chart versions 1.4.X (e.g. 1.4.0 - 1.4.6)
  # seem to give a spark-operator usage error (flag provided but not defined:
  # -webhook-secret-name) when used with the latest published image
  # version (v1beta2-1.4.3-3.5.0) at:
  # https://github.com/kubeflow/spark-operator/pkgs/container/spark-operator
  # Using the latest 1.3.X version of the chart (v1.3.2) as a workaround.
  version = var.helm_chart_version
  set {
    name = "image.repository"
    value = "ghcr.io/kubeflow/spark-operator"
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }

  # The mutating admission webhook is required in order for taint
  # tolerations and node selectors to work.
  set {
    name  = "webhook.enable"
    value = true
  }
  set {
    name  = "webhook.port"
    value = 443
  }
}