variable "aws_region" {
  description = "AWS region where Terraform state storage will be created."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "zuri-platform"
}

variable "environment" {
  description = "Environment used for tagging."
  type        = string
  default     = "bootstrap"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "devops"
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = "retail-online"
}

variable "application" {
  description = "Application tag value."
  type        = string
  default     = "zurishop"
}