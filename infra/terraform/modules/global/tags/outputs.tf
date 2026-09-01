output "tags" {
  description = "Standard ZuriMart tags for AWS and Azure resources."
  value       = local.all_tags
}

output "gcp_labels" {
  description = "Standard ZuriMart labels for GCP resources."
  value = {
    for key, value in local.all_tags :
    lower(replace(key, "/[^a-zA-Z0-9_-]/", "-")) => lower(value)
  }
}

output "required_tag_keys" {
  description = "Required tag keys that must exist on every resource."
  value       = keys(local.base_tags)
}