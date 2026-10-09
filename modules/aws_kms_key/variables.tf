## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "kms_key_description" {
  type        = string
  description = "S3 KMS Encryption Key Description"
  default     = "Example S3|KMS Encryption Key"
}

variable "kms_retention_days" {
  type        = number
  description = "KMS Encryption Key Retention Window in Days"
  default     = 7
}

variable "iam_policy_id" {
  type        = string
  description = "S3 KMS Encryption Key Description"
  default     = "ExampleS3KMSKeyPolicyDoc"
}