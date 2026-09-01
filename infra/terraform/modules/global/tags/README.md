# Global Tags Module

This module standardizes tagging for all ZuriMart Terraform-managed resources.

## Usage

```hcl
module "tags" {
  source      = "../../modules/global/tags"
  environment = "dev"
}


```

# For AWS and Azure:
tags = module.tags.tags

# For GCP:
labels = module.tags.gcp_labels