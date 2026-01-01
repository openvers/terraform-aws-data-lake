<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-aws-blob-trigger/tf-integration-test.yml?style=flat&logo=github&label=CD%20(January%202026)" height="25px"/>
</p>


# Terraform AWS Data Lake Module

## Overview

This repository provides a modular, production-ready Terraform implementation for provisioning a secure, scalable AWS Data Lake. It includes:
- Medallion architecture S3 buckets (Bronze, Silver, Gold)
- KMS encryption
- IAM roles and policies
- Secure access patterns and lifecycle management

The modules are designed for flexibility and can be used for both development and production environments.

## Module Structure

- `modules/aws_kms_key/` – KMS key creation and policy management
- `modules/s3_bucket/` – S3 bucket creation, versioning, encryption, lifecycle, and access block

---

## Usage

```hcl
module "data_lake" {
  source = "../" # or the path to this module

  bronze_bucket_name = "my-bronze-bucket"
  silver_bucket_name = "my-silver-bucket"
  gold_bucket_name   = "my-gold-bucket"

  providers = {
    aws.auth_session = aws.auth_session
  }
}
```

## Testing

A test harness is provided in the `test/` directory. It includes:
- Service account and OIDC federation setup
- Automated creation of a sample file and upload to the bronze bucket using Terraform's `local_file` and `aws_s3_object` resources
- Output variables for integration with CI/CD pipelines

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits

Store the identical Secrets in Github Organization/Repository to local workstation

```bash
cat <<EOF > ~/creds/aws.secrets
# Terraform.io Token
TF_API_TOKEN=[COPY/PASTE MANUALLY]

# Github PAT
GITHUB_TOKEN=$(git auth token)

# AWS
AWS_REGION=$(aws configure get region)
AWS_OIDC_PROVIDER_ARN=[COPY/PASTE MANUALLY]
AWS_CLIENT_ID=[COPY/PASTE MANUALLY]
AWS_CLIENT_SECRET=[COPY/PASTE MANUALLY]
AWS_ROLE_TO_ASSUME=[COPY/PASTE MANUALLY]
AWS_ROLE_EXTERNAL_ID=[COPY/PASTE MANUALLY]
EOF
```

### Local Deployment Testing

```bash
export $(grep -v '^#' ~/creds/aws.secrets | xargs)
export AWS_PROFILE=sso-admin

aws sso login --profile $AWS_PROFILE

terraform -chdir ./test init
terraform -chdir ./test plan
terraform -chdir ./test apply -auto-approve
terraform -chdir ./test destroy -auto-approve
```

### Manual Dispatch Testing

```bash
# Try the Terraform Read job first
act -j terraform-dispatch-plan \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-apply \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-destroy \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)
```

### Integration Testing

```bash
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show) \
    --artifact-server-path /tmp/artifacts
```

### Unit Testing

```bash
act -j terraform-unit-tests \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)
```

---

## License

See [LICENSE](./LICENSE) for details.

