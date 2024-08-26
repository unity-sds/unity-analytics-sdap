terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_api_gateway_rest_api" "sdap_api" {
  name = "unity-as-sdap-api-tf"
  description = "API for SDAP"
}

resource "aws_api_gateway_resource" "sdap_api_parent" {
  rest_api_id = aws_api_gateway_rest_api.sdap_api.id
  parent_id = aws_api_gateway_rest_api.sdap_api.root_resource_id
  path_part = "sdap"
}

resource "aws_api_gateway_resource" "sdap_api_proxy_plus" {
  rest_api_id = aws_api_gateway_rest_api.sdap_api.id
  parent_id = aws_api_gateway_resource.sdap_api_parent.id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "sdap_api_proxy_plus_method" {
  rest_api_id = aws_api_gateway_rest_api.sdap_api.id
  resource_id   = aws_api_gateway_resource.sdap_api_proxy_plus.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

data "aws_lb" "sdap_lb" {
  tags = {
    "elbv2.k8s.aws/cluster" = "unity-as-venuedev-sdap"
  }
}

resource "aws_api_gateway_vpc_link" "sdap_api_vpc_link" {
  name        = "sdap_api_vpc_link"
  description = "VPC Link for SDAP API"
  target_arns = [data.aws_lb.sdap_lb.arn]
}

resource "aws_api_gateway_integration" "sdap_api_proxy_plus_integration" {
  rest_api_id = aws_api_gateway_rest_api.sdap_api.id
  resource_id = aws_api_gateway_resource.sdap_api_proxy_plus.id
  http_method = aws_api_gateway_method.sdap_api_proxy_plus_method.http_method
  type = "HTTP_PROXY"
  uri = join("/", ["http:/",
                   join(":", [data.aws_lb.sdap_lb.dns_name, "8080"]),
		   "nexus",
		   "{proxy}"])
  integration_http_method = "GET"
  connection_type = "VPC_LINK"
  connection_id = aws_api_gateway_vpc_link.sdap_api_vpc_link.id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "sdap_api_deployment" {
  depends_on = [aws_api_gateway_integration.sdap_api_proxy_plus_integration]
  rest_api_id = aws_api_gateway_rest_api.sdap_api.id
  stage_name  = var.sdap_api_stage
  stage_description = "SDAP API deployed at ${timestamp()}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssm_parameter" "sdap_health_check" {
  name        = "/unity/healthCheck/analysis-services/sdap"
  description = "Health check URL for SDAP."
  type        = "String"
  value = jsonencode({
    "componentName": "SDAP",
    "healthCheckUrl": join("/", [
      aws_api_gateway_deployment.sdap_api_deployment.invoke_url,
      "sdap/list"
      ])
    "landingPageUrl": "",
  })
  tags = var.tags
}
