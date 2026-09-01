locals {
  examples = {
    dev_aws_networking_vpc = {
      environment   = "dev"
      cloud         = "aws"
      layer         = "networking"
      resource_type = "vpc"
    }

    dev_aws_networking_subnet = {
      environment   = "dev"
      cloud         = "aws"
      layer         = "networking"
      resource_type = "subnet"
    }

    staging_aws_kubernetes_eks = {
      environment   = "staging"
      cloud         = "aws"
      layer         = "kubernetes"
      resource_type = "eks"
    }

    production_azure_kubernetes_aks = {
      environment   = "production"
      cloud         = "azure"
      layer         = "kubernetes"
      resource_type = "aks"
    }

    dev_gcp_kubernetes_gke = {
      environment   = "dev"
      cloud         = "gcp"
      layer         = "kubernetes"
      resource_type = "gke"
    }

    production_aws_databases_rds = {
      environment   = "production"
      cloud         = "aws"
      layer         = "databases"
      resource_type = "rds"
    }
  }
}

module "example_names" {
  source   = "../../modules/global/naming"
  for_each = local.examples

  project       = var.project
  environment   = each.value.environment
  cloud         = each.value.cloud
  layer         = each.value.layer
  resource_type = each.value.resource_type
}