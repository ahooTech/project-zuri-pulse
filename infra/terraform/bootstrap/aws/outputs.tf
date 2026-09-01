output "s3_bucket_name" {
  description = "S3 bucket used for AWS Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_lock_table" {
  description = "DynamoDB table used for AWS Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "AWS region used for Terraform state."
  value       = var.aws_region
}