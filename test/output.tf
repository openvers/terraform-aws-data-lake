output "service_account_client_id" {
  description = "AWS Service Account Client ID"
  value       = module.aws_service_account.access_id
  sensitive   = true
}

output "service_account_client_secret" {
  description = "AWS Service Account Client Secret"
  value       = module.aws_service_account.access_token
  sensitive   = true
}

output "bronze_bucket_id" {
  description = "AWS Medallion Bronze Storage Bucket ID"
  value       = module.data_lake.bronze_bucket_id
}

output "silver_bucket_id" {
  description = "AWS Medallion Silver Storage Bucket ID"
  value       = module.data_lake.silver_bucket_id
}

output "gold_bucket_id" {
  description = "AWS Medallion Gold Storage Bucket ID"
  value       = module.data_lake.gold_bucket_id
}

output "assume_role_arn" {
  description = "AWS IAM Assume Role ARN for GitHub OIDC pytest access"
  value       = module.aws_identity_federation.assume_role_arn
}
