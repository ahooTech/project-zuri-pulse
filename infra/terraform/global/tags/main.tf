locals {
  environments = [
    "dev",
    "staging",
    "production"
  ]
}

module "standard_tags" {
  source   = "../../modules/global/tags"
  for_each = toset(local.environments)

  project     = var.project
  environment = each.value
  owner       = var.owner
  cost_center = var.cost_center
  application = var.application
  managed_by  = var.managed_by
}