# ZuriMart Terraform Landing Zone

This directory contains the Terraform infrastructure code for PROJECT ZURI PULSE Phase 2.

The goal is to build a repeatable, secure, version-controlled, multi-cloud landing zone for ZuriMart across AWS, Azure, and GCP.

## Repository Layout

```text
infra/terraform/
├── modules/
│   ├── aws/
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── rds/
│   │   ├── elasticache/
│   │   ├── s3/
│   │   ├── iam/
│   │   ├── alb/
│   │   ├── route53/
│   │   └── cloudwatch/
│   ├── azure/
│   │   ├── resource-group/
│   │   ├── vnet/
│   │   ├── aks/
│   │   ├── keyvault/
│   │   ├── monitor/
│   │   └── storage/
│   └── gcp/
│       ├── network/
│       ├── gke/
│       ├── storage/
│       ├── artifact-registry/
│       ├── iam/
│       └── bigquery/
├── environments/
│   ├── dev/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── kubernetes/
│   │   ├── databases/
│   │   └── monitoring/
│   ├── staging/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── kubernetes/
│   │   ├── databases/
│   │   └── monitoring/
│   └── production/
│       ├── networking/
│       ├── security/
│       ├── kubernetes/
│       ├── databases/
│       └── monitoring/
├── global/
│   ├── dns/
│   ├── iam/
│   └── tags/
├── backends/
│   ├── aws/
│   ├── azure/
│   └── gcp/
├── scripts/
└── policies/
```

# Phase 2 Principles

Everything is provisioned through Terraform.
No manual console-created infrastructure.
State is stored remotely and locked.
State is separated by environment and layer.
Secrets are never committed to Git.
Every resource is tagged.
Every infrastructure change goes through Git and pull request review.
Expensive workloads are not applied until they are needed. 


# State Separation Strategy

Each environment will use separate Terraform state files per layer:

| Layer      | Purpose                                                    |
|------------|------------------------------------------------------------|
| networking | VPCs, VNets, subnets, routing, peering                     |
| security   | IAM, security groups, Key Vault, service accounts          |
| kubernetes | EKS, AKS, GKE clusters                                     |
| databases  | RDS, ElastiCache, Azure SQL, Cloud SQL, BigQuery           |
| monitoring | CloudWatch, Azure Monitor, GCP Monitoring, logging buckets |



# Tagging Strategy

All resources must carry the following baseline tags: 

Project     = "zuri-platform"
Environment = "dev | staging | production"
Owner       = "devops"
CostCenter  = "retail-online"
Application = "zurishop"
ManagedBy   = "terraform"



# Safety Rules 

Never commit .tfstate.
Never commit backend .hcl files under backends/.
Never commit *.auto.tfvars.json files containing secrets.
Never commit cloud credentials.
Always run terraform plan before terraform apply.
Always destroy unused dev resources to control cost.



