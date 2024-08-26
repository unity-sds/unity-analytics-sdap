variable "aws_region" {
  type = string
}

variable "sdap_api_stage" {
  type = string
  default = "dev"
}

variable "tags" {
  type = map(string)
  default = {}
}
