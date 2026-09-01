variable "project" {
  description = "Project name used for tagging."
  type        = string
  default     = "zuri-platform"
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