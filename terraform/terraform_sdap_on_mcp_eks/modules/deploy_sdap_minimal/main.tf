# This terraform deploys a minimal configuration of SDAP on a
# configured Kubernetes cluster.
#
# Prerequisites:
# 1) The deployment host must have Kubernetes and Helm installed
# 2) Configure a Kubernetes cluster to use.  For AWS/EKS clusters:
#    > aws eks update-kubeconfig --name ${cluster_name}
#                                --region ${cluster_region}
#    You should then have a valid configuration in ~/.kube/config
# 3) The Kubeflow Spark-On-K8s-Operator has been installed.
# 4) Install charts for dependencies: nginx-ingress, rabbitmq, solr, cassandra
#    > cd ../../../../helm
#    > helm repo add bitnami https://charts.bitnami.com/bitnami
#    > helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#    > helm dep update
# 5) Deploy the minimal configuration of SDAP with Terraform
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

provider "kubernetes" {
  config_path = "~/.kube/config"
  token = data.aws_eks_cluster_auth.this.token
}

data kubernetes_nodes "driver_nodes" {
  metadata {
    labels = {
      "eks.amazonaws.com/nodegroup" = "sdap-driver"
    }
  }
}

locals {
  driver_node_name = data.kubernetes_nodes.driver_nodes.nodes[0].metadata.0.name
}

resource "kubernetes_node_taint" "driver_taint" {
  metadata {
    name = local.driver_node_name
  }
  taint {
    key    = "eks.amazonaws.com/nodegroup"
    value  = "sdap-driver"
    effect = "NoSchedule"
  }
}

resource "kubernetes_namespace" "sdap_namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_storage_class" "sdap_storage_class" {
  metadata {
    name = "sdap-store"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  allow_volume_expansion = true
  reclaim_policy      = "Delete"
  parameters = {
    type = "gp2"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_config_map" "sdap_collections" {
  depends_on = [kubernetes_namespace.sdap_namespace]
  metadata {
    name = "collections-config"
    namespace = var.namespace
  }
  data = {
    "collections.yml" = "${file("../../../../k8s_deployment/sdap_collections/collections.yml")}"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    token = data.aws_eks_cluster_auth.this.token
  }
}

resource "helm_release" "sdap_minimal" {
  depends_on = [kubernetes_node_taint.driver_taint,
	        kubernetes_namespace.sdap_namespace,
		kubernetes_storage_class.sdap_storage_class,
		kubernetes_config_map.sdap_collections]
  name = "sdap"
  version = 0.1
  chart = "../../../../helm"
  namespace = var.namespace
  values = [
    "${file("../../../../k8s_deployment/values/values_noingest_1exec.yaml")}"
  ]
}
