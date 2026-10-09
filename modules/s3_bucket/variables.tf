## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "bucket_name" {
  type        = string
  description = "AWS Storage Bucket Name"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Encryption Key ARN"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "lifecycle_standard_days" {
  type        = number
  description = "S3 Lifecycle Days before Transition to Standard Storage Class"
  default     = 30
}

variable "lifecycle_glacier_days" {
  type        = number
  description = "S3 Lifecycle Days before Transition to Glacier Storage Class"
  default     = 60
}

variable "lifecycle_expiration_days" {
  type        = number
  description = "S3 Lifecycle Days before Expiration"
  default     = 90
}

variable "kms_encryption_algorithm" {
  type        = string
  description = "S3 KMS Encryption Key Algorithm"
  default     = "aws:kms"
}