locals {
  base_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
    ManagedBy   = var.managed_by
  }

  all_tags = merge(local.base_tags, var.extra_tags)
}