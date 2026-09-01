variable "project" {
  description = "Project name used in resource names."
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

variable "cloud" {
  description = "Cloud provider."
  type        = string

  validation {
    condition = contains(
      [
        "aws",
        "azure",
        "gcp"
      ],
      var.cloud
    )

    error_message = "Cloud must be one of: aws, azure, gcp."
  }
}

variable "layer" {
  description = "Infrastructure layer."
  type        = string

  validation {
    condition = contains(
      [
        "networking",
        "security",
        "kubernetes",
        "databases",
        "monitoring",
        "application",
        "global"
      ],
      var.layer
    )

    error_message = "Layer must be one of: networking, security, kubernetes, databases, monitoring, application, global."
  }
}

variable "resource_type" {
  description = "Short resource type identifier, such as vpc, subnet, sg, eks, rds, aks, gke."
  type        = string
  default     = ""

  validation {
    condition = (
      var.resource_type == "" ||
      can(regex("^[a-z0-9-]{1,20}$", var.resource_type))
    )

    error_message = "resource_type must contain only lowercase letters, numbers, and hyphens, and must be 20 characters or fewer."
  }
}

variable "suffix" {
  description = "Optional suffix for uniqueness."
  type        = string
  default     = ""

  validation {
    condition = (
      var.suffix == "" ||
      can(regex("^[a-z0-9-]{1,20}$", var.suffix))
    )

    error_message = "suffix must contain only lowercase letters, numbers, and hyphens, and must be 20 characters or fewer."
  }
}

variable "max_length" {
  description = "Maximum length of the generated name."
  type        = number
  default     = 60

  validation {
    condition     = var.max_length >= 10 && var.max_length <= 255
    error_message = "max_length must be between 10 and 255."
  }
}