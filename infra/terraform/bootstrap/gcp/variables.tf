variable "gcp_project_id" {
  description = "GCP project ID where Terraform state storage will be created."
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "Default GCP region for provider-level operations."
  type        = string
  default     = "us-central1"
}

variable "gcp_bucket_location" {
  description = "GCS bucket location. Can be a region or multi-region."
  type        = string
  default     = "US"
}

variable "project" {
  description = "Project name used for naming and labels."
  type        = string
  default     = "zuri-platform"
}

variable "environment" {
  description = "Environment used for labels."
  type        = string
  default     = "bootstrap"
}

variable "owner" {
  description = "Owner label value."
  type        = string
  default     = "devops"
}

variable "cost_center" {
  description = "Cost center label value."
  type        = string
  default     = "retail-online"
}

variable "application" {
  description = "Application label value."
  type        = string
  default     = "zurishop"
}