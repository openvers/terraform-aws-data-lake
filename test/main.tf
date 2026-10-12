terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-aws-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  assume_role_policies = [
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRoleWithWebIdentity"
      ]
      principals = [{
        type        = "Federated"
        identifiers = [var.OIDC_PROVIDER_ARN]
      }]
      conditions = [
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values = [
            "repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}"
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:iss"
          values = [
            "https://token.actions.githubusercontent.com",
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values = [
            "sts.amazonaws.com",
          ]
        },
      ]
    },
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [module.aws_service_account.service_account_arn]
      }]
      conditions = []
    }
  ]

  service_account_roles_list = [
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:AttachRolePolicy",
    "iam:TagRole",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:PassRole",
    "iam:CreatePolicy",
    "iam:GetPolicy",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:GetPolicyVersion",
    "iam:ListPolicyVersions",
    "iam:DetachRolePolicy",
    "iam:DeletePolicy",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "iam:ListAttachedGroupPolicies",
    "iam:AttachGroupPolicy",
    "iam:GetGroupPolicy",
    "iam:PutGroupPolicy",
    "iam:DeleteGroupPolicy",
    "iam:DetachGroupPolicy",
    "kms:ScheduleKeyDeletion",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:Create*",
    "kms:Describe*",
    "kms:Enable*",
    "kms:List*",
    "kms:Put*",
    "kms:Disable*",
    "kms:Get*",
    "kms:Delete*",
    "s3:*",
    "s3-object-lambda:*",
    "lambda:*",
    "logs:*",
    "sns:*"
  ]

  suffix = "test-${random_string.this.result}"
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with CLI Credentials.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "accountgen"
}

##---------------------------------------------------------------------------------------------------------------------
## AWS SERVICE ACCOUNT MODULE
##
## This module provisions an AWS service account along with associated roles and security groups.
##
## Parameters:
## - `service_account_name`: The display name of the new AWS Service Account.
## - `service_account_path`: The new AWS Service Account IAM Path.
## - `roles_list`: List of IAM roles to bing to new AWS Service Account.
##
## Providers:
## - `aws.accountgen`: Alias for the AWS provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "aws_service_account" {
  source = "github.com/openvers/terraform-aws-service-account.git?ref=42fb073acd6cdd793a6d064ddb0a1800906c1712"

  service_account_name = var.service_account_name
  service_account_path = var.service_account_path
  roles_list           = local.service_account_roles_list

  providers = {
    aws.accountgen = aws.accountgen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with new Service Account Authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "auth_session"

  access_key = module.aws_service_account.access_id
  secret_key = module.aws_service_account.access_token
}

##---------------------------------------------------------------------------------------------------------------------
## AWS IDENTITY FEDERATION MODULE
##
## This module configured IAM Trust policies to provide OIDC federated access from Github Actions to AWS.
##
## Parameters:
## - `assume_role_policies`: List of OIDC trust policies.
##
## Providers:
## - `aws.accountgen`: Alias for the AWS provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "aws_identity_federation" {
  source     = "github.com/openvers/terraform-aws-service-account.git//modules/identity_federation?ref=42fb073acd6cdd793a6d064ddb0a1800906c1712"
  depends_on = [module.aws_service_account]

  assume_role_policies  = local.assume_role_policies
  service_account_group = module.aws_service_account.group_name
  policy_roles_list = [
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "s3:Get*",
    "s3:Put*",
    "s3:List*",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:Decrypt",
  ]

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATA LAKE MODULE
##
## Provisions a complete AWS Data Lake environment, including S3 buckets for bronze, silver, and gold medallion data layers,
## IAM roles and policies, KMS encryption, Lambda function integration, and supporting resources.
##
## Parameters:
## - `bronze_bucket_name`: Name of the S3 bucket for raw/bronze data.
## - `silver_bucket_name`: Name of the S3 bucket for processed/silver data.
## - `gold_bucket_name`: Name of the S3 bucket for curated/gold data.
##
## Notes:
## - This module is designed for end-to-end data lake testing and development.
## - Additional configuration may be required for Lambda, KMS, and IAM integration depending on your use case.
## ---------------------------------------------------------------------------------------------------------------------
module "data_lake" {
  source     = "../"
  depends_on = [module.aws_service_account]

  bronze_bucket_name = "${local.suffix}-bronze"
  silver_bucket_name = "${local.suffix}-silver"
  gold_bucket_name   = "${local.suffix}-gold"

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## LOCAL FILE RESOURCE FOR S3 TESTING
##
## Generates a sample file at build time for testing S3 uploads to the bronze bucket.
## The file includes a timestamp and test metadata.
##
## Parameters:
## - `content`: The contents of the sample file (includes timestamp).
## - `filename`: The path where the file will be created locally.
## ---------------------------------------------------------------------------------------------------------------------
resource "local_file" "bronze_sample" {
  content  = <<-EOT
This is a sample file for testing S3 upload to the bronze bucket via Terraform.
Uploaded by: Terraform test
Date: ${timestamp()}
EOT
  filename = "${path.module}/sample_bronze_upload.txt"
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 OBJECT RESOURCE FOR TESTING
##
## Uploads the generated sample file to the bronze S3 bucket for testing purposes.
##
## Parameters:
## - `bucket`: The name of the bronze S3 bucket (from module or variable).
## - `key`: The S3 object key (path in the bucket).
## - `source`: The local file to upload.
## - `etag`: Ensures the object is updated if the file content changes.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_object" "bronze_test_upload" {
  provider   = aws.auth_session
  depends_on = [local_file.bronze_sample]

  bucket = module.data_lake.bronze_bucket_id
  key    = "test/sample_bronze_upload.txt"
  source = local_file.bronze_sample.filename
}
