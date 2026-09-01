output "name" {
  description = "Standardized resource name."
  value       = local.final
}

output "raw_name" {
  description = "Raw name before normalization and truncation."
  value       = local.raw_name
}