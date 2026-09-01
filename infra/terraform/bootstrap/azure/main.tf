resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  storage_account_name = "zuripulsetf${random_string.suffix.result}"
  resource_group_name  = "${var.project}-tfstate-${random_string.suffix.result}-rg"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "terraform_state" {
  name     = local.resource_group_name
  location = var.azure_location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}