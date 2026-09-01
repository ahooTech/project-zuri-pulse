# Global Naming Module

This module standardizes resource naming for all ZuriMart Terraform-managed resources.

## Naming Pattern

```text
<project>-<environment>-<cloud>-<layer>-<resource_type>-<suffix>

```

# Example

module "vpc_name" {
  source        = "../../modules/global/naming"
  environment   = "dev"
  cloud         = "aws"
  layer         = "networking"
  resource_type = "vpc"
}

# This produces:

zuri-platform-dev-aws-net-vpc