# Terraform Backend Configurations

This folder contains Terraform backend partial configuration files.

## Important Rules

Actual `*.hcl` backend files are generated locally and are ignored by Git.

They contain environment-specific backend names such as S3 bucket names, Azure storage account names, and GCS bucket names.

Only the following should be committed:

- `README.md`
- `*.hcl.example`

## Backend File Naming Convention

Files are named using:

```text
<environment>-<layer>.hcl
```

# Examples:

dev-networking.hcl
staging-kubernetes.hcl
production-databases.hcl


# State Separation Strategy

Each environment and layer has its own Terraform state file:

| Environment | Layers                                                  |
| ----------- | ------------------------------------------------------- |
| dev         | networking, security, kubernetes, databases, monitoring |
| staging     | networking, security, kubernetes, databases, monitoring |
| production  | networking, security, kubernetes, databases, monitoring |

This limits blast radius and makes Terraform operations safer.
