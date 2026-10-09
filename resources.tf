terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.auth_session,
      ]
    }
  }
}

data "aws_caller_identity" "auth_session" {
  provider = aws.auth_session
}

locals {
  suffix                = "${var.program_name}-${var.project_name}"
  service_principal_arn = data.aws_caller_identity.auth_session.arn
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS KMS KEY MODULE
##
## This module provisions a customer-managed AWS KMS Key for encrypting data at rest.
## The key can be used to secure S3 buckets, Lambda environment variables, and other AWS resources.
##
## Parameters:
## - `kms_key_description`: A description for the KMS key.
## - `kms_retention_days`: Waiting period for key rotation (in days).
## - `iam_policy_id`: (Optional) Alias for the KMS key.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_kms_key" {
  source = "./modules/aws_kms_key"

  kms_key_description = "${title(replace(local.suffix, "-", " "))} KMS Key for Data Lake"
  kms_retention_days  = 10
  iam_policy_id       = "${replace(title(replace(local.suffix, "-", " ")), " ", "")}KMSRootPolicyDoc"

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION BRONZE BUCKET MODULE
## 
## S3 Bucket to Store Bronze Medallion Level/ Raw Data in AWS Data Lake.
## 
## Parameters:
## - `bucket_name`: S3 bucket name.
## - `kms_key_arn`: KMS encryption key ARN.
## ---------------------------------------------------------------------------------------------------------------------
module "bronze_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = var.bronze_bucket_name
  kms_key_arn = module.aws_kms_key.kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION SILVER BUCKET MODULE
## 
## S3 Bucket to Store Silver Medallion Level/ Process Data in AWS Data Lake.
## 
## Parameters:
## - `bucket_name`: S3 bucket name.
## - `kms_key_arn`: KMS encryption key ARN.
## ---------------------------------------------------------------------------------------------------------------------
module "silver_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = var.silver_bucket_name
  kms_key_arn = module.aws_kms_key.kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION GOLD BUCKET MODULE
## 
## S3 Bucket to Store Gold Medallion Level/ Curated Data in AWS Data Lake.
## 
## Parameters:
## - `bucket_name`: S3 bucket name.
## - `kms_key_arn`: KMS encryption key ARN.
## ---------------------------------------------------------------------------------------------------------------------
module "gold_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = var.gold_bucket_name
  kms_key_arn = module.aws_kms_key.kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY DOCUMENT DATA SOURCE
## 
## Define a policy document to grant assume role STS permissions to 
## Service Principal.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  provider = aws.auth_session

  statement {
    sid     = "${replace(title(replace(local.suffix, "-", " ")), " ", "")}AssumeRolePolicyDoc"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = [local.service_principal_arn]
      type        = "AWS"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ROLE RESOURCE
## 
## Create a Data Lake Role to grant permissions to Data Lake.
## 
## Parameters:
## - `name`: AWS IAM Role name.
## - `assume_role_policy`: AWS IAM Policy document JSON.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  provider = aws.auth_session

  name               = "${local.suffix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY DOCUMENT DATA SOURCE
## 
## Define a policy document to grant our Service Principal
## permissions to read/write into the Data Lake S3 Buckets, and
## encrypt data with KMS.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "data_lake" {
  provider = aws.auth_session

  statement {
    sid    = "${replace(title(replace(local.suffix, "-", " ")), " ", "")}S3PolicyDoc"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.bronze_bucket_name}",
      "arn:aws:s3:::${var.bronze_bucket_name}/*",
      "arn:aws:s3:::${var.silver_bucket_name}",
      "arn:aws:s3:::${var.silver_bucket_name}/*",
      "arn:aws:s3:::${var.gold_bucket_name}",
      "arn:aws:s3:::${var.gold_bucket_name}/*",
    ]
  }

  statement {
    sid    = "${replace(local.suffix, "-", "")}KMSPolicyDoc"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      module.aws_kms_key.kms_key_arn,
    ]
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ROLE POLICY RESOURCE
## 
## Bind Data Lake role with S3 and KMS policy document.
## 
## Parameters:
## - `name`: AWS IAM Role policy name.
## - `role`: AWS IAM Role ID.
## - `policy`: AWS IAM Policy document JSON.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "this" {
  provider = aws.auth_session

  name   = replace(title(replace("${local.suffix}RolePolicy", "-", " ")), " ", "")
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.data_lake.json
}