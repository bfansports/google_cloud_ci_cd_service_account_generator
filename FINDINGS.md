# Security Audit: google_cloud_ci_cd_service_account_generator

**Date:** 2026-02-17
**Auditor:** DevOps Engineer (AI-assisted)
**Scope:** IAM security, key rotation, least privilege, credential exposure, Terraform state, provider hygiene
**Repo:** bfansports/google_cloud_ci_cd_service_account_generator

---

## Critical

### C-1: `roles/firebase.admin` is overly permissive for CI/CD deployments

**File:** `modules/google_cloud_ci_cd_service_account_generator/firebase_service_account.tf:13`

```hcl
role = "roles/firebase.admin"
```

`roles/firebase.admin` grants full read/write/delete access to every Firebase service (Firestore, RTDB, Storage, Hosting, Auth, Functions, etc.). CI/CD pipelines that only deploy Hosting or Functions do not need admin over Auth or Firestore data.

**Risk:** A compromised service account key can delete production databases, exfiltrate user data, or modify auth providers.

**Recommendation:** Replace with the minimum set of roles the CI/CD pipeline actually uses. Typical Firebase deployment needs:
- `roles/firebase.developAdmin` (if deploying hosting/functions)
- `roles/firebasehosting.admin` (hosting-only deployments)
- `roles/cloudfunctions.developer` (Cloud Functions deployments)
- `roles/firebaserules.admin` (security rules only)

Audit which Firebase CLI commands run in CI/CD and grant only those roles. Use `roles/firebase.viewer` as a baseline and add write roles incrementally.

---

### C-2: Terraform state backend has no state locking (commented-out DynamoDB)

**File:** All 6 `terragrunt.hcl` files (dev-eu, qa-eu, prod-eu x 2 modules)

```hcl
# dynamodb_table = "terraform-state-lock" # TODO: Create a DynamoDB table for state locking
```

Without state locking, concurrent `terraform apply` runs can corrupt the state file, leading to orphaned GCP service accounts, duplicate keys, or lost resource tracking. This is especially dangerous since every apply recreates ALL service account keys.

**Risk:** Two engineers running `make apply-prod-eu` simultaneously can corrupt state and leave untracked service account keys in GCP that are never rotated or deleted.

**Recommendation:** Create DynamoDB tables for state locking immediately:
```bash
for env in dev qa prod; do
  aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile ${env}-eu
done
```
Then uncomment the `dynamodb_table` line in all terragrunt.hcl files.

---

### C-3: Service account keys stored in Terraform state as plaintext

**File:** `modules/google_cloud_ci_cd_service_account_generator/firebase_service_account_key.tf`

The `google_service_account_key` resource stores the full private key in Terraform state (`private_key` attribute). The S3 backend has no server-side encryption configured.

```hcl
backend "s3" {
  profile = "${local.aws_profile}"
  bucket  = "${local.terraform_bucket_name}"
  key     = "${local.module_name}.tfstate"
  region  = "eu-west-1"
}
```

No `encrypt = true`, no `kms_key_id`, no bucket policy enforcing encryption.

**Risk:** Anyone with S3 read access to the state bucket can extract every service account private key for every Firebase project.

**Recommendation:** Add encryption to the S3 backend:
```hcl
backend "s3" {
  encrypt        = true
  kms_key_id     = "alias/terraform-state"
  # ... existing fields
}
```
Also apply an S3 bucket policy denying `s3:GetObject` without `aws:SecureTransport`.

---

## High

### H-1: Docker container runs as root with host credential mounts

**File:** `Makefile:5-11`

```makefile
DOCKER_RUN = docker run -it --rm \
    -e AWS_PROFILE=$(AWS_PROFILE) \
    -v ~/.aws/config:/root/.aws/config \
    -v ~/.aws/sso/cache/:/root/.aws/sso/cache/ \
    -v ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json \
    -v $(PWD):/app/ \
    -w /app/$*
```

The container runs as `root` and mounts the host's AWS SSO cache and Google Cloud ADC credentials. A supply-chain attack on the `devopsinfra/docker-terragrunt` image could exfiltrate both AWS and GCP credentials.

**Risk:** Compromise of the third-party Docker image gives the attacker AWS SSO tokens and GCP application default credentials.

**Recommendations:**
1. Pin the Docker image by SHA digest, not just by tag.
2. Add `--read-only` flag and mount only specific credential files needed.
3. Consider running Terragrunt natively (the `make dev` target installs it locally via `tenv`), eliminating the Docker attack surface entirely.
4. Mount credentials as read-only: `-v ~/.aws/config:/root/.aws/config:ro`

---

### H-2: No key count limits -- every `apply` creates keys for ALL Firebase projects in the org

**File:** `modules/google_cloud_ci_cd_service_account_generator/data.tf`

```hcl
data "google_projects" "firebase_projects" {
  filter = "labels.firebase:enabled lifecycleState:ACTIVE"
}
```

This dynamically discovers ALL projects with `firebase:enabled` label. If a new Firebase project is added anywhere in the GCP org, it automatically gets a service account with `roles/firebase.admin` and a key stored in SSM on the next apply.

**Risk:** Unintended scope creep. New projects get admin service accounts without explicit opt-in. An attacker who can add the `firebase:enabled` label to any GCP project gets an admin service account key delivered to SSM.

**Recommendation:** Use an explicit allowlist of project IDs instead of dynamic discovery:
```hcl
variable "firebase_project_ids" {
  type        = list(string)
  description = "Explicit list of Firebase project IDs to manage"
}
```
Or add a more specific label like `labels.bfan-cicd:enabled` that is restricted by IAM policy.

---

### H-3: `roles/firebase.growthAdmin` may be overly broad for FCM/SNS integration

**File:** `modules/firebase_cloud_messaging_aws_sns/firebase_service_account.tf:15`

```hcl
role = "roles/firebase.growthAdmin"
```

The commented-out alternatives show this was a workaround. `roles/firebase.growthAdmin` includes permissions for Firebase A/B Testing, Remote Config, Dynamic Links, In-App Messaging, and Predictions -- not just Cloud Messaging.

**Risk:** Service accounts used by SNS for push notifications have write access to Remote Config and A/B Testing experiments.

**Recommendation:** Create a custom IAM role with only the FCM permissions needed:
```hcl
resource "google_project_iam_custom_role" "fcm_sender" {
  role_id     = "fcmSender"
  title       = "FCM Message Sender"
  permissions = [
    "cloudmessaging.messages.create",
    "firebase.projects.get"
  ]
}
```

---

### H-4: Malformed IAM ARNs in SNS platform application

**File:** `modules/firebase_cloud_messaging_aws_sns/aws_sns_platform_application.tf:18-19`

```hcl
failure_feedback_role_arn = "arn:aws:iam::${local.aws_account_id}:role/SNSFailureFeedback"
success_feedback_role_arn = "arn:aws:iam::${local.aws_account_id}:role/SNSSuccessFeedback"
```

These ARNs have a double colon (`iam::`) which is the correct format for IAM (global service, no region). However, the roles `SNSFailureFeedback` and `SNSSuccessFeedback` are referenced but not created by this Terraform code. If they do not exist, SNS delivery failure logging is silently disabled.

**Risk:** Push notification delivery failures go unmonitored. No alerting on FCM delivery issues.

**Recommendation:** Either create the IAM roles in this Terraform config, or add a `data` source to validate they exist:
```hcl
data "aws_iam_role" "sns_failure_feedback" {
  name = "SNSFailureFeedback"
}
```

---

## Medium

### M-1: Key rotation period is 1 day but depends on manual `terraform apply`

**File:** `modules/google_cloud_ci_cd_service_account_generator/firebase_service_account_key.tf:3`

```hcl
rotation_days = 1 # note this requires the terraform to be run regularly
```

The `time_rotating` resource only marks keys as needing rotation after 1 day. But rotation only happens when someone runs `terraform apply`. If nobody runs it for weeks, keys persist far beyond 1 day.

**Risk:** False sense of rotation security. Keys may live for weeks or months without actual rotation.

**Recommendation:**
1. Set up a scheduled CI/CD pipeline (GitHub Actions cron) to run `make apply-*` daily.
2. Or increase `rotation_days` to a realistic value (e.g., 90 days) and add monitoring for key age.
3. Add a CloudWatch alarm or GCP monitoring alert when keys exceed the rotation threshold.

---

### M-2: Stale provider versions with known vulnerabilities

**File:** `versions.tf` (root) and `modules/*/versions.tf`

Root `versions.tf`:
```hcl
aws = { version = "4.64.0" }  # Released April 2023, ~3 years old
```

Module `versions.tf`:
```hcl
google = { version = "5.32.0" }  # Released June 2024
aws    = { version = "5.52.0" }  # Released June 2024
time   = { version = "0.11.2" }  # Released May 2024
```

The root `versions.tf` pins AWS provider to 4.64.0 while modules use 5.52.0. This version mismatch could cause conflicts. Additionally, all versions are 1.5+ years old.

**Risk:** Missing security patches, bug fixes, and deprecated API compatibility.

**Recommendation:** Update all providers to current versions. Align root and module version constraints. Use `~>` constraint for minor version flexibility:
```hcl
aws = { version = "~> 5.80" }
google = { version = "~> 6.15" }
```

---

### M-3: SSM parameters created without explicit KMS encryption key

**File:** `modules/google_cloud_ci_cd_service_account_generator/aws_ssm_parameter_account_key.tf`

```hcl
resource "aws_ssm_parameter" "firebase_service_account_key" {
  type  = "SecureString"
  value = base64decode(...private_key)
}
```

`SecureString` uses the default `aws/ssm` KMS key. This key cannot have restricted access policies -- anyone with SSM read permissions can decrypt.

**Risk:** Broad SSM read access in the AWS account means broad access to all service account keys.

**Recommendation:** Use a customer-managed KMS key with a restrictive key policy:
```hcl
resource "aws_ssm_parameter" "firebase_service_account_key" {
  type   = "SecureString"
  key_id = aws_kms_key.firebase_credentials.arn
  value  = base64decode(...)
}
```

---

### M-4: No `google_project_iam_binding` audit -- using additive `iam_member` without checking existing bindings

**File:** `modules/*/firebase_service_account.tf`

`google_project_iam_member` is additive -- it does not manage the complete role membership. Other service accounts or users with the same role will not be visible or managed by Terraform.

**Risk:** Cannot detect if additional principals have been manually granted `roles/firebase.admin` outside of Terraform. No drift detection for IAM.

**Recommendation:** Consider using `google_project_iam_binding` (authoritative for a role) for the specific service account roles, or implement IAM audit logging and alerts for out-of-band changes.

---

### M-5: Terragrunt config duplication across all 6 environment directories

**Files:** All `*/*/terragrunt.hcl` files are identical.

The identical terragrunt.hcl is copy-pasted 6 times. Any security fix (e.g., enabling state encryption) must be applied to all 6 files manually.

**Risk:** Configuration drift between environments. A security fix applied to prod but missed in dev.

**Recommendation:** Use a root `terragrunt.hcl` with `include` blocks:
```hcl
# root terragrunt.hcl
remote_state { ... }
retry_max_attempts = 5
```
Then each environment file only specifies its overrides.

---

## Low

### L-1: OpenTofu 1.9.0 and Terragrunt 0.72.0 may have known issues

**Files:** `.opentofu-version`, `.terragrunt-version`

No specific CVEs identified, but pinned versions should be reviewed quarterly.

**Recommendation:** Add a Dependabot or Renovate config to track OpenTofu and Terragrunt releases.

---

### L-2: `firebase_service_account_keys/` directory has `.gitkeep` but no README

The directory exists for local testing but has no documentation on proper handling of downloaded keys.

**Recommendation:** Add a `README.md` in the directory:
```
Keys downloaded here are for local testing only.
NEVER commit .json files. They are gitignored.
Delete keys after use: rm -f *.json
```

---

### L-3: No `.terraform-docs.yml` or automated documentation

Module inputs, outputs, and provider requirements are not auto-documented.

**Recommendation:** Add `terraform-docs` generation to CI.

---

### L-4: Makefile exposes GCP token in curl validation

**File:** `Makefile:43-51`

```makefile
@token=$$(gcloud auth application-default print-access-token); \
if curl -s -H "Authorization: Bearer $$token" https://www.googleapis.com/oauth2/v1/userinfo ...
```

The access token appears in process listings (`ps aux`). Low risk since it is short-lived (1 hour) and only used locally.

**Recommendation:** Minor. Consider using `gcloud auth application-default print-access-token --format=json | jq -r .email` to avoid raw token exposure, or use `gcloud auth list` to check the active account.

---

## Agent Skill Improvements

### S-1: CLAUDE.md should document GCP IAM patterns and security gotchas

The existing CLAUDE.md covers operations well but lacks:
- IAM role explanations for the roles actually used
- Key management lifecycle documentation
- Security review checklist for changes
- Cross-cloud credential flow diagram

**Action:** Updated in this PR.

### S-2: CLAUDE.md should warn about the dynamic project discovery risk

The `data.google_projects` filter auto-discovers projects. Any CLAUDE.md consumer (human or AI) should understand this implicit behavior.

**Action:** Added to Gotchas section in this PR.

---

## Positive Observations

1. **Key rotation intent is correct.** Using `time_rotating` + `keepers` is the right Terraform pattern for key rotation. The implementation just needs a scheduled executor.

2. **SSM SecureString usage.** Keys are stored as `SecureString` in SSM, not plaintext `String`. This provides baseline encryption.

3. **Service account per-project isolation.** Each Firebase project gets its own service account, limiting blast radius if one key is compromised. This is better than a single org-wide service account.

4. **Gitignore for credential files.** `.gitignore` correctly excludes `firebase_service_account_keys/*.json` and `.terraform` state.

5. **Environment separation.** Dev/QA/Prod are cleanly separated with distinct AWS profiles and state buckets.

6. **Retry logic for known provider bug.** The `retryable_errors` config handles the known Google provider race condition gracefully.

7. **Version pinning.** All providers, OpenTofu, and Terragrunt versions are pinned, preventing supply-chain drift.

8. **Google Cloud auth validation.** The Makefile validates the correct account (`dev-google@bfansports.com`) before running, preventing accidental operations with the wrong identity.
