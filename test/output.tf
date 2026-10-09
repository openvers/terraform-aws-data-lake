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