variable "project" {
  description = "Project name used for tagging."
  type        = string
  default     = "zuri-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition = contains(
      [
        "dev",
        "staging",
        "production",
        "bootstrap",
        "dr"
      ],
      var.environment
    )

    error_message = "Environment must be one of: dev, staging, production, bootstrap, dr."
  }
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

variable "managed_by" {
  description = "Tool responsible for managing the resource."
  type        = string
  default     = "terraform"
}

variable "extra_tags" {
  description = "Additional tags to merge with the standard tags."
  type        = map(string)
  default     = {}
}