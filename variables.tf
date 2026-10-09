## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "bronze_bucket_name" {
  type        = string
  description = "Medallion Bronze Landing Zone (S3 Bucket Name)"
}

variable "silver_bucket_name" {
  type        = string
  description = "Medallion Silver Landing Zone (S3 Bucket Name)"
}

variable "gold_bucket_name" {
  type        = string
  description = "Medallion Gold Landing Zone (S3 Bucket Name)"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "program_name" {
  type        = string
  description = "Program Name"
  default     = "dp-lessons"
}

variable "project_name" {
  type        = string
  description = "Project name for the data lake"
  default     = "ex-data-lake"
}