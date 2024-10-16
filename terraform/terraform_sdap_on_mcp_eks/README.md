# Orderly Terraform Deployment of SDAP

Apache SDAP (Science Data Analytics Platform) is a cloud-scale analytics
platform with a number of built-in algorithms for computations like
area-averaged time series, time-averaged maps, correlation maps,
Hovmoller maps, etc.  It is expected that these analytics capabilities would
have wide applicability to many science data processing applications, including
dataset comparisons for verification and validation of new data products.

SDAP is natively deployed locally using Docker or in the cloud with Helm.
This repository was developed with the end goal of making SDAP compatible and
easily deployed within a different existing system, MDPS/Unity Science Data
System (SDS), based mainly on Terraform.

This directory contains a set of Terraform scripts to deploy SDAP into a
cloud venue managed by the MDPS/Unity SDS project.  The underlying cloud
platform used is Amazon Web Services (AWS).  These scripts may be used as a
basis and modified as needed for deployment to other deployment platforms
including AWS without the resources specific to MDPS/Unity SDS.

## Overview of Terraform structure and deployment process

The endgoal of this Terraform deployment is to provision an AWS EKS cluster
with 1 driver node and 1 or more worker nodes.  Without taking care,
Kubernetes will assign system components to any node in the cluster that has
room.  Typically that means that the end result of each deployment could look
different and have different performance qualities.  Instead, this set of
Terraform scripts are applied in sequence in the order shown below.
The end results is that the deployment is done in stages that ensure that
SDAP components are mapped in an orderly and repeatable manner
to the driver or worker nodes as appropriate.

| Step | Directory | Description |
| ---- | --------- | ----------- |
| 0    | ./        | Set up environment |
| 1a   | ./        | Authenticate to AWS |
| 1b   | ./	   | Provision EKS cluster |
| 1c   | ./        | Configure `kubectl` and `helm`
| 2    | ./modules/deploy_spark_operator | Deploy the Spark-on-K8s-Operator |
| 3a    | ./modules/deploy_sdap_minimal | Deploy SDAP webapp, datastore, 1 executor |
| 3b    | ./modules/deploy_sdap_full | Deploy all SDAP executors |
| 3c    | ./modules/deploy_sdap_ingest | Deploy SDAP ingest components |
| 3d    | ./modules/deploy_ingress | Deploy SDAP nginx ingress+load balancer |
| 4    | ./modules/deploy_api_gateway | Deploy MDPS/Unity API for SDAP |

Note that the configuration values for these Terraform script are not provided
in this repository since they are expected to be specific to each deployment.
You can reference the `variables.tf` file in each Terraform module directory to
see what configuration values are expected and provide those values on the
command line or by adding your own `terraform.tfvars` files.

## Step 0 - Set up environment

Ensure you are on a system with `kubectl`, `helm`, and `terraform` installed.
In addition, you should be able to authenticate to an account on AWS.

Clone this repo.

    git clone https://github.com/unity-sds/unity-analytics-sdap.git
    cd unity-analytics-sdap 

The Terraform deployment scripts here rely on the contents of the following
folders in this repo:

| Directory | Description |
| --------- | ----------- |
| ./helm    | A versioned snapshot of the SDAP helm directory from https://github.com/apache/sdap-nexus/helm |
| ./k8s_deployment | Various required Kubernetes resource configurations |
| ./terraform/terraform_sdap_on_mcp_eks | The Terraform deployment scripts |

## Step 1a - Authenticate to AWS

Authenticate to your AWS account.  The environment variables that need to be
set will depend on your personal setup, but may include the following:

    export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
    export AWS_SESSION_TOKEN=<AWS_SESSION_TOKEN>

## Step 1b - Provision EKS Cluster

Use the MDPS/Unity common services EKS cluster provisioning automation scripts
to provision an EKS cluster.

    cd ./terraform/terraform_sdap_on_mcp_eks
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 1c - Configure `kubectl` and `helm` repos

Configure your `kubectl` to manage the Kubernetes cluster you provisioned
in step 1b above.

    aws eks update-kubeconfig --name ${cluster_name}
                              --region ${cluster_region}

You should now have a valid configuration in `~/.kube/config`.

Add the Kubeflow spark-operator helm repo, Bitnami, and ingress-nginx repos

    cd ./helm
    helm repo add spark-operator https://kubeflow.github.io/spark-operator
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm dep update
    cd ..

## Step 2 - Deploy the Spark-on-K8s-Operator

SDAP depends on the Spark-on-K8s-Operator, so we need to install that first.
As of April 2024, this operator is now hosted in the Kubeflow org, so we
will use the Kubeflow helm repository.  Ensure your helm has that repo added
in step 1c above.

    cd ./terraform/terraform_sdap_on_mcp_eks/modules/deploy_spark_operator
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 3a - Deploy SDAP webapp, datastore, and 1 executor 

We will start by deploying just the following:

1. The SDAP webapp
1. RabbitMQ
1. The SDAP datastore components (Solr, Cassandra, Zookeeper)
1. A single Spark executor (for now)

The Terraform script automatically ensures that the driver node hosts the
webapp and RabbitMQ, and each worker node gets one replica pod each of Solr,
Cassandram, and Zookeeper.  In addition, the single Spark executor will be
run on one of the worker nodes.

    cd ./modules/deploy_sdap_minimal
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 3b - Deploy all SDAP executors

Next we will scale up to the full set of Spark executors.  These will be
distributed evenly across the available worker nodes.

    cd ./modules/deploy_sdap_full
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 3c - Deploy SDAP ingest components

The following SDAP ingest components are deployed next, and are hosted by the
driver node:

1. Collections Manager
1. Granule Ingester

These components work in concert to discover new data granules for registered
datasets, partition the data into tiles, and ingest them in to the SDAP
datastore.

    cd ./modules/deploy_sdap_ingest
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 3d - Deploy SDAP nginx ingress and load balancer

Now we are ready to start exposing SDAP endpoints outside of the Kubernetes
cluster.  In this step the SDAP nginx ingress component is run on the same
driver node that hosts the webapp.  A load balancer is provisioned in AWS and
configured to connect to the webapp listeners.

    cd ./modules/deploy_sdap_ingress
    terraform init
    terraform plan
    terraform apply
    cd ../..

## Step 4 - Deploy MDPS/Unity API for SDAP

Depending on your personal IT security processes and preferences you can skip
or modify this step as needed.  For the MDPS/Unity project, users are expected
to interact with service endpoints through the AWS API Gateway.  In this step
that API is deployed and connected to the SDAP load balancer deployed in step
3d above.

    cd ./modules/deploy_sdap_ingress
    terraform init
    terraform plan
    terraform apply
    cd ../..
