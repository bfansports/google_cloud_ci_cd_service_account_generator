# Google Cloud CI/CD Service Account Generator

This Terraform project generates Google Cloud service account keys for each Firebase project and uploads them to an S3 bucket.
Those API keys will be used by the CI/CD pipeline to access the Firebase projects.

## Getting started

Set up the Google Cloud credentials with your `@bfansports.com` account:

```bash
gcloud auth application-default login
```

*It needs `Security Admin` role, if you don't have it, then ask someone to go to [this link](https://console.cloud.google.com/iam-admin/iam?authuser=0&hl=en&orgonly=true&folder=&organizationId=744998649083&supportedpurview=organizationId) and add the role to your user.*

Set up the AWS PROD credentials with

```bash
swe prod-eu
```

## Usage

Every time there is a new Firebase project, you generate a new Google Cloud service account key and add it to the S3 bucket with:

```bash
terraform apply
```

*Don't be alarmed if it's recreating all the API keys, I set it up to rotate every time you run `terraform apply`*
*If `google_project_iam_member.firebase-admin` fails, then you need to add the `Security Admin` role to your account.*

## Why ?

The Firebase CLI is deprecating the `FIREBASE_TOKEN` environment variable that accessed all the Firebase projects at once. See <https://github.com/firebase/firebase-tools#authentication>

Now we need individual Google Cloud service account credentials for each Firebase project. This is because the Firebase CLI uses the Google Cloud credentials to access the Firebase project.

```bash
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath ./bfan-google-cloud-service-accounts/firebase_service_account_keys/bfan-stadefrancais.json)
firebase projects:list
```

## First Setup

In case you delete the S3 bucket, you need to recreate it with:

```bash
# Make the Terraform state bucket in AWS PROD
aws s3 mb s3://bfan-google-cloud-service-accounts
```
