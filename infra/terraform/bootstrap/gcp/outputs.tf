output "state_bucket_name" {
  description = "GCS bucket used for GCP Terraform state."
  value       = google_storage_bucket.terraform_state.name
}