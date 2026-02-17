# google_cloud_ci_cd_service_account_generator

## What This Is

Terraform/OpenTofu infrastructure-as-code project that generates Google Cloud service account keys for each Firebase project and uploads them to AWS SSM Parameter Store. Enables CI/CD pipelines (Bitrise, GitHub Actions) to access Firebase projects using individual service account credentials instead of deprecated `FIREBASE_TOKEN`. Manages multi-environment (dev/qa/prod) Firebase authentication infrastructure.

## Tech Stack

- **IaC Tool**: OpenTofu/Terraform
- **Cloud Providers**: Google Cloud (Firebase/GCP), AWS (SSM Parameter Store)
- **Version Control**: Terragrunt (environment management)
- **Languages**: HCL (Terraform configuration)
- **Authentication**: Google Cloud Application Default Credentials, AWS CLI

## Quick Start

```bash
# Authenticate with Google Cloud
gcloud auth application-default login

# OR set up development environment
make dev

# Plan changes for production
make plan-prod-eu

# Apply changes (generates and uploads service account keys)
make apply-prod-eu

# For dev/qa environments
make plan-dev-eu
make apply-dev-eu
```

<!-- Ask: What does `make dev` do? Set up gcloud auth and AWS profile? -->
<!-- Ask: Are the generated keys automatically rotated? How often? -->

## Project Structure

```
google_cloud_ci_cd_service_account_generator/
├── versions.tf                   # Terraform/provider versions
├── Makefile                      # Environment commands
├── modules/                      # Terraform modules
├── dev-eu/                       # Dev environment config
├── qa-eu/                        # QA environment config
├── prod-eu/                      # Prod environment config
├── firebase_service_account_keys/  # Generated keys (gitignored)
└── README.md
```

## Dependencies

**Tools:**
- OpenTofu (specified in `.opentofu-version`)
- Terragrunt (specified in `.terragrunt-version`)
- gcloud CLI
- AWS CLI

**Cloud Accounts:**
- Google Cloud org access with `Security Admin` role
- AWS account with SSM Parameter Store write permissions

**Authentication:**
- `dev-google@bfansports.com` — Google Cloud account (or any with Security Admin role)
- AWS profile configured (via `swe` command)

## API / Interface

**Generated SSM Parameters:**
- Path: `/google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/<project-name>`
- Format: JSON service account key
- Used by: CI/CD pipelines for Firebase CLI authentication

**Example Usage in CI/CD:**
```bash
# Download service account key from SSM
aws ssm get-parameter \
  --name /google_cloud_ci_cd_service_account_generator/firebase_service_account_keys/bfan-stadefrancais \
  --with-decryption --output text --query Parameter.Value \
  > ./firebase_service_account_keys/bfan-stadefrancais.json

# Set as GCloud credentials
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath ./firebase_service_account_keys/bfan-stadefrancais.json)

# Use Firebase CLI
firebase projects:list
```

## Key Patterns

- **Multi-environment**: Separate Terragrunt configs for dev/qa/prod
- **Key Rotation**: Keys recreated on every `terraform apply` (intentional rotation)
- **Centralized Storage**: All keys in AWS SSM for easy CI/CD access
- **IAM-as-Code**: Service accounts and IAM bindings managed via Terraform
- **Cross-cloud**: Google Cloud service accounts stored in AWS infrastructure

## Environment

**Google Cloud:**
- Org ID: `744998649083`
- Required Role: `Security Admin` (for IAM bindings)
- Firebase projects: `bfan-stadefrancais`, `fkcrvenazvezda`, etc.

**AWS:**
- SSM Parameter Store (encrypted)
- S3 backend for Terraform state: `s3://bfan-terraform-state-bucket-{env}`

**Environment Variables:**
- `GOOGLE_APPLICATION_CREDENTIALS` — Path to service account JSON (output)

<!-- Ask: What Firebase projects are managed? Is there a list in the Terraform config? -->
<!-- Ask: Are there Terragrunt dependencies between dev/qa/prod? -->

## Deployment

**First-time Setup:**
```bash
# Create Terraform state bucket in AWS
swe prod-eu
aws s3 mb "s3://bfan-terraform-state-bucket-$ENV"
aws s3api put-bucket-versioning \
  --bucket "bfan-terraform-state-bucket-$ENV" \
  --versioning-configuration Status=Enabled
```

**Deploying Changes:**
```bash
# Authenticate with Google Cloud
gcloud auth application-default login

# Plan changes
make plan-prod-eu

# Apply (generates service accounts, uploads to SSM)
make apply-prod-eu
```

**Key Rotation:**
- Keys rotate automatically on every `terraform apply`
- CI/CD pipelines must fetch fresh keys on each build

## Testing

<!-- Ask: Are there tests for the Terraform modules? -->
<!-- Ask: How is the infrastructure validated before apply? -->

**Manual Validation:**
```bash
# Test generated key locally
export GOOGLE_APPLICATION_CREDENTIALS=./firebase_service_account_keys/bfan-stadefrancais.json
firebase projects:list
```

## Gotchas

- **Key Rotation on Apply**: Every `terraform apply` recreates ALL keys — not a bug, it's intentional
- **Security Admin Role**: Terraform fails if Google Cloud user lacks `Security Admin` role
- **Firebase Token Deprecation**: Old `FIREBASE_TOKEN` env var no longer works; must use service account keys
- **S3 State Bucket**: Must be created manually before first Terraform run
- **Cross-account Access**: `fkcrvenazvezda` project requires `dev-google@bfansports.com` account specifically
- **Terragrunt Version**: `.terragrunt-version` file locks version; update only when necessary
- **OpenTofu vs Terraform**: Project uses OpenTofu (Terraform fork); ensure correct binary installed
- **SSM Parameter Paths**: Hardcoded prefix; changing requires CI/CD pipeline updates
- **Key File Gitignore**: Generated keys in `firebase_service_account_keys/` must stay gitignored
- **IAM Propagation Delay**: After creating service account, IAM bindings may take 60s to propagate
- **Firebase CLI Version**: Older Firebase CLI versions don't support service account auth