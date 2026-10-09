output "kms_key_arn" {
  description = "KMS Encryption Key ARN"
  value       = module.aws_kms_key.kms_key_arn
  sensitive   = true
}

output "kms_key_id" {
  description = "KMS Encryption Key ID"
  value       = module.aws_kms_key.kms_key_id
  sensitive   = true
}

output "kms_key_encryption_id" {
  description = "KMS Encryption ID"
  value       = module.aws_kms_key.encryption_id
  sensitive   = true
}

output "bronze_bucket_arn" {
  description = "AWS Medallion Bronze Storage Bucket ARN"
  value       = module.bronze_bucket.bucket_arn
}

output "bronze_bucket_id" {
  description = "AWS Medallion Bronze Storage Bucket ID"
  value       = module.bronze_bucket.bucket_id
}

output "silver_bucket_arn" {
  description = "AWS Medallion Silver Storage Bucket ARN"
  value       = module.silver_bucket.bucket_arn
}

output "silver_bucket_id" {
  description = "AWS Medallion Silver Storage Bucket ID"
  value       = module.silver_bucket.bucket_id
}

output "gold_bucket_arn" {
  description = "AWS Medallion Gold Storage Bucket ARN"
  value       = module.gold_bucket.bucket_arn
}

output "gold_bucket_id" {
  description = "AWS Medallion Gold Storage Bucket ID"
  value       = module.gold_bucket.bucket_id
}