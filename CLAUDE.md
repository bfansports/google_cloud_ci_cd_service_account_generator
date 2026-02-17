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

## Project Structure

```
google_cloud_ci_cd_service_account_generator/
├── versions.tf                   # Terraform/provider versions
├── Makefile                      # Environment commands
├── modules/                      # Terraform modules
│   ├── google_cloud_ci_cd_service_account_generator/  # CI/CD SA keys → SSM
│   └── firebase_cloud_messaging_aws_sns/              # FCM SA keys → SNS
├── dev-eu/                       # Dev environment config
├── qa-eu/                        # QA environment config
├── prod-eu/                      # Prod environment config
├── firebase_service_account_keys/  # Generated keys (gitignored)
└── README.md
```

## Dependencies

**Tools:**
- OpenTofu 1.9.0 (specified in `.opentofu-version`)
- Terragrunt 0.72.0 (specified in `.terragrunt-version`)
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

## GCP IAM Roles & Security

### Roles Used

| Role | Module | Purpose | Scope |
|------|--------|---------|-------|
| `roles/firebase.admin` | `google_cloud_ci_cd_service_account_generator` | CI/CD Firebase deployments | Per-project |
| `roles/firebase.growthAdmin` | `firebase_cloud_messaging_aws_sns` | FCM push via AWS SNS | Per-project |

### Least Privilege Considerations

- `roles/firebase.admin` is broad — grants full read/write/delete across all Firebase services. For CI/CD that only deploys Hosting or Functions, prefer scoped roles like `roles/firebasehosting.admin` or `roles/cloudfunctions.developer`.
- `roles/firebase.growthAdmin` includes FCM but also A/B Testing, Remote Config, and Dynamic Links. A custom role with only `cloudmessaging.messages.create` is more restrictive.
- Both modules use `google_project_iam_member` (additive). This does NOT remove existing role bindings — it only adds. Out-of-band IAM changes are not detected.

### Service Account Key Lifecycle

1. `data.google_projects` discovers Firebase projects by label (`firebase:enabled`)
2. One `google_service_account` is created per discovered project
3. `time_rotating` (1-day period) triggers key recreation on `terraform apply`
4. `google_service_account_key` generates a new JSON key
5. Key is base64-decoded and stored as `SecureString` in AWS SSM
6. Old key is destroyed by Terraform (replaced in state)

**Critical detail:** Step 3 only triggers when `terraform apply` actually runs. If nobody runs apply, keys persist beyond the 1-day rotation window. There is no scheduled automation enforcing rotation.

### Key Security Architecture

```
GCP Org (744998649083)
  └── Firebase Project (e.g., bfan-stadefrancais)
        └── Service Account (bfan-firebase-ci-cd-{env})
              └── SA Key (JSON, rotated on apply)
                    └── Stored in AWS SSM (SecureString, default KMS)
                          └── Read by CI/CD (Bitrise, GitHub Actions)
```

**Cross-cloud trust boundary:** GCP credentials cross into AWS. Compromise of either cloud's IAM could expose the other's resources. The SSM parameter path is the single choke point.

## Environment

**Google Cloud:**
- Org ID: `744998649083`
- Required Role: `Security Admin` (for IAM bindings)
- Firebase projects: dynamically discovered via `labels.firebase:enabled`

**AWS:**
- SSM Parameter Store (encrypted with default `aws/ssm` KMS key)
- S3 backend for Terraform state: `s3://bfan-terraform-state-bucket-{env}`
- State locking: NOT enabled (DynamoDB table TODO)

**Environment Variables:**
- `GOOGLE_APPLICATION_CREDENTIALS` — Path to service account JSON (output)
- `AWS_PROFILE` — AWS CLI profile for target environment

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
- No automated schedule exists — rotation depends on manual runs

## Testing

No automated tests exist for the Terraform modules.

**Manual Validation:**
```bash
# Test generated key locally
export GOOGLE_APPLICATION_CREDENTIALS=./firebase_service_account_keys/bfan-stadefrancais.json
firebase projects:list
```

**Recommended validation before apply:**
```bash
# Always plan first
make plan-prod-eu
# Review the plan output for unexpected changes
# Check service account count matches expected Firebase projects
# Verify no resources are being destroyed unexpectedly
```

## Gotchas

- **Key Rotation on Apply**: Every `terraform apply` recreates ALL keys — not a bug, it's intentional rotation. CI/CD pipelines must fetch keys on every build, not cache them.
- **Security Admin Role**: Terraform fails if Google Cloud user lacks `Security Admin` role on the org.
- **Firebase Token Deprecation**: Old `FIREBASE_TOKEN` env var no longer works; must use service account keys.
- **S3 State Bucket**: Must be created manually before first Terraform run.
- **Cross-account Access**: `fkcrvenazvezda` project requires `dev-google@bfansports.com` account specifically.
- **Terragrunt Version**: `.terragrunt-version` file locks version; update only when necessary.
- **OpenTofu vs Terraform**: Project uses OpenTofu (Terraform fork); ensure correct binary installed.
- **SSM Parameter Paths**: Hardcoded prefix; changing requires CI/CD pipeline updates across all repos that consume these keys.
- **Key File Gitignore**: Generated keys in `firebase_service_account_keys/` must stay gitignored. Never commit JSON key files.
- **IAM Propagation Delay**: After creating service account, IAM bindings may take 60s to propagate.
- **Firebase CLI Version**: Older Firebase CLI versions don't support service account auth.
- **Dynamic Project Discovery**: `data.google_projects` auto-discovers ALL Firebase-labeled projects in the org. Adding the `firebase:enabled` label to any GCP project causes it to get a service account with admin permissions on next apply. This is a security-sensitive behavior.
- **No State Locking**: DynamoDB state lock is commented out. Never run concurrent `terraform apply` against the same environment — state corruption risk.
- **State Contains Secrets**: Terraform state files contain base64-encoded service account private keys. Treat state buckets as highly sensitive. Restrict S3 access and enable server-side encryption.
- **Provider Version Mismatch**: Root `versions.tf` pins AWS 4.64.0, modules pin 5.52.0. The module version takes precedence during apply, but the root constraint may cause confusion.
- **Docker Image Trust**: The Makefile uses `devopsinfra/docker-terragrunt` (third-party image). Verify image integrity before use. Consider pinning by SHA digest.
- **Additive IAM Only**: `google_project_iam_member` does not remove role bindings added outside Terraform. IAM drift is not detected or corrected.

## GCP IAM Patterns (Reference)

### Service Account Naming
- CI/CD accounts: `bfan-firebase-ci-cd-{env}` (per environment)
- FCM/SNS accounts: `bfan-firebase-fcm-sns-{env}` (per environment)
- Account IDs are 6-30 chars, lowercase, hyphens allowed.

### Key Management Best Practices
1. **Prefer Workload Identity Federation** over service account keys where possible (GKE, Cloud Run, GitHub Actions OIDC). Keys are a last resort.
2. **Monitor key age** via `gcloud iam service-accounts keys list` or GCP Asset Inventory.
3. **Limit key count**: GCP allows max 10 keys per service account. With 1-day rotation and no cleanup, old keys may accumulate if Terraform state is lost.
4. **Never download keys locally** unless for debugging. Use SSM for CI/CD access.
5. **Audit key usage**: Enable GCP Audit Logs for `iam.serviceAccountKeys.create` to track who generates keys.

### IAM Role Hierarchy (Firebase)
- `roles/firebase.admin` > `roles/firebase.developAdmin` > `roles/firebase.viewer`
- `roles/firebase.growthAdmin` covers: FCM, A/B Testing, Remote Config, Dynamic Links, In-App Messaging, Predictions
- For FCM only: create a custom role with `cloudmessaging.messages.create`

### Cross-Cloud Credential Flow
```
Developer runs `make apply-prod-eu`
  → Authenticates to GCP via ADC (gcloud auth application-default login)
  → Authenticates to AWS via SSO profile (aws sso login --profile prod-eu)
  → Terragrunt discovers Firebase projects via GCP API
  → Creates service accounts + keys in GCP
  → Stores keys in AWS SSM Parameter Store
  → CI/CD reads from SSM at build time
```
