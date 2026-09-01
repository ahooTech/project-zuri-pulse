output "resource_group_name" {
  description = "Resource group containing Azure Terraform state storage."
  value       = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = "Storage account used for Azure Terraform state."
  value       = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = "Blob container used for Azure Terraform state."
  value       = azurerm_storage_container.terraform_state.name
}