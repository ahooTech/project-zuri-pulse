resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.project}-tfstate-${random_id.suffix.hex}"

  common_labels = {
    project     = var.project
    environment = var.environment
    owner       = var.owner
    cost-center = var.cost_center
    application = var.application
    managed-by  = "terraform"
  }
}

resource "google_storage_bucket" "terraform_state" {
  name          = local.bucket_name
  location      = var.gcp_bucket_location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  labels = local.common_labels
}