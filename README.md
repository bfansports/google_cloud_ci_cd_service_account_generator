# Google Cloud CI/CD Service Account Generator

This Terraform project generates Google Cloud service account keys for each Firebase project and uploads them to SSM Parameter Store.
Those API keys will be used by the CI/CD pipeline to access the Firebase projects.

## Getting started

Set up the Google Cloud credentials with `dev-google@bfansports.com` account:

```bash
gcloud auth application-default login
```

*We are using `dev-google@bfansports.com` because it also needs access to the `fkcrvenazvezda` Firebase project. Once it's accessible to all bFAN developers, you can use any account that has the  `Security Admin` role.*

*It needs `Security Admin` role, if you don't have it, then ask someone to go to [this link](https://console.cloud.google.com/iam-admin/iam?authuser=0&hl=en&orgonly=true&folder=&organizationId=744998649083&supportedpurview=organizationId) and add the role to your user.*

## Usage

Every time there is a new Firebase project, you generate a new Google Cloud service account key and add it to the SSM Parameter Store with:

```bash
terragrunt run-all apply
```

*Don't be alarmed if it's recreating all the API keys, I set it up to rotate every time you run `terraform apply`*

*If `google_project_iam_member.firebase-admin` fails, then you need to add the `Security Admin` role to your account.*

## Why ?

The Firebase CLI is deprecating the `FIREBASE_TOKEN` environment variable that accessed all the Firebase projects at once. See <https://github.com/firebase/firebase-tools#authentication>

Now we need individual Google Cloud service account credentials for each Firebase project. This is because the Firebase CLI uses the Google Cloud credentials to access the Firebase project.

```bash
# Download the JSON from SSM Parameter Store
aws ssm get-parameter --name /google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/bfan-stadefrancais --with-decryption --output text --query Parameter.Value > ./firebase_service_account_keys/bfan-stadefrancais.json
# Set the GCloud credentials in the environment
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath ./firebase_service_account_keys/bfan-stadefrancais.json)
# Use the credentials to access the Firebase project
firebase projects:list
```

## First Setup

In case you delete the S3 bucket, you need to recreate it with:

```bash
# Make the Terraform state bucket in AWS, and enable versioning
swe prod-eu
aws s3 mb "s3://bfan-terraform-state-bucket-$ENV"
aws s3api put-bucket-versioning --bucket "bfan-terraform-state-bucket-$ENV" --versioning-configuration Status=Enabled
```
