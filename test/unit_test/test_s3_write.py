"""Unit Test: AWS S3 Medallion Bucket Write

Verifies write/read access to the AWS Data Lake bronze, silver, and gold S3
buckets using either environment credentials or GitHub OIDC role assumption.

Local Testing Steps:
```
terraform -chdir=./test init && \
terraform -chdir=./test apply -auto-approve

export BRONZE_BUCKET_ID=$(terraform -chdir=./test output -raw bronze_bucket_id)
export SILVER_BUCKET_ID=$(terraform -chdir=./test output -raw silver_bucket_id)
export GOLD_BUCKET_ID=$(terraform -chdir=./test output -raw gold_bucket_id)

python3 -m pytest test/unit_test -m "github and env" -rs

terraform -chdir=./test destroy -auto-approve
```
"""

import asyncio
import json
import logging
import os
import uuid

import boto3
import pytest
import s3fs


BUCKET_ENV_VARS = {
    "bronze": "BRONZE_BUCKET_ID",
    "silver": "SILVER_BUCKET_ID",
    "gold": "GOLD_BUCKET_ID",
}


def _required_env(name):
    value = os.getenv(name)
    if not value:
        pytest.skip(f"Required environment variable is not set: {name}")
    return value


def _medallion_buckets():
    return [(layer, _required_env(env_var)) for layer, env_var in BUCKET_ENV_VARS.items()]


def _oidc_filesystem_kwargs():
    assume_role_arn = _required_env("ASSUME_ROLE_ARN")
    oidc_token = _required_env("OIDC_TOKEN")
    region_name = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION") or "us-east-1"

    sts = boto3.client("sts", region_name=region_name)
    response = sts.assume_role_with_web_identity(
        RoleArn=assume_role_arn,
        RoleSessionName="github-data-lake-pytest-oidc-session",
        WebIdentityToken=oidc_token,
    )
    credentials = response["Credentials"]

    return {
        "key": credentials["AccessKeyId"],
        "secret": credentials["SecretAccessKey"],
        "token": credentials["SessionToken"],
        "client_kwargs": {"region_name": region_name},
    }


def _write_blob(fs, path, payload):
    with fs.open(path, "w") as file:
        file.write(json.dumps(payload))


def _read_blob(fs, path):
    with fs.open(path, "rb") as file:
        return json.loads(file.read())


def _delete_blob(fs, path):
    fs.rm(path)


async def _verify_bucket_write(layer, bucket_name, payload, **filesystem_kwargs):
    fs = s3fs.S3FileSystem(**filesystem_kwargs)
    path = f"s3://{bucket_name}/test/{layer}-{uuid.uuid4()}.json"

    try:
        await asyncio.to_thread(_write_blob, fs, path, payload)
        result = await asyncio.to_thread(_read_blob, fs, path)

        assert result["test_value"] == payload["test_value"]
    finally:
        await asyncio.to_thread(_delete_blob, fs, path)


async def _verify_medallion_bucket_writes(payload, **filesystem_kwargs):
    await asyncio.gather(
        *(
            _verify_bucket_write(layer, bucket_name, payload, **filesystem_kwargs)
            for layer, bucket_name in _medallion_buckets()
        )
    )


@pytest.mark.github
@pytest.mark.env
def test_aws_env_s3_write(payload=None):
    logging.info("Pytest | Test AWS S3 Write with Environment Credentials")
    payload = payload or {"test_value": str(uuid.uuid4())}

    asyncio.run(_verify_medallion_bucket_writes(payload))


@pytest.mark.github
@pytest.mark.oidc
def test_aws_oidc_s3_write(payload=None):
    logging.info("Pytest | Test AWS S3 Write with GitHub OIDC")
    payload = payload or {"test_value": str(uuid.uuid4())}

    asyncio.run(_verify_medallion_bucket_writes(payload, **_oidc_filesystem_kwargs()))
