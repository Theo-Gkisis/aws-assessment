# Unleash Live — AWS DevOps Engineer Assessment

Multi-region AWS infrastructure using Terraform.
Regions: **us-east-1** (primary) and **eu-west-1** (secondary).

---

## Architecture Overview

```
us-east-1
├── Cognito User Pool (shared authorizer for both regions)
├── VPC / Public Subnets
├── API Gateway HTTP  →  POST /greet   (JWT-protected)
│                    →  POST /dispatch (JWT-protected)
├── Lambda – Greeter    → DynamoDB + SNS publish
├── Lambda – Dispatcher → ECS RunTask
├── ECS Fargate Cluster → SNS publish (from container)
└── DynamoDB – GreetingLogs

eu-west-1  (identical compute stack, same Cognito pool)
├── VPC / Public Subnets
├── API Gateway HTTP  →  POST /greet
│                    →  POST /dispatch
├── Lambda – Greeter
├── Lambda – Dispatcher
├── ECS Fargate Cluster
└── DynamoDB – GreetingLogs
```

---

## Multi-Region Provider Structure

Two aliased AWS providers are declared in [`providers.tf`](providers.tf):

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}
```

The root [`main.tf`](main.tf) instantiates every module **twice** — once per region — passing the correct provider alias via the `providers` meta-argument:

```hcl
module "compute_us" {
  source    = "./modules/compute"
  providers = { aws = aws.us_east_1 }
  region    = "us-east-1"
  ...
}

module "compute_eu" {
  source    = "./modules/compute"
  providers = { aws = aws.eu_west_1 }
  region    = "eu-west-1"
  ...
}
```

The `cognito` module is instantiated **once** in `us-east-1` only. Both compute stacks reference the same Cognito User Pool ID and endpoint, so authentication is centralised while compute is fully regional.

Each child module declares a `required_providers` block in its own `providers.tf` to accept the passed-in provider without a default:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- AWS CLI configured with credentials that have sufficient permissions
- Python 3.12+ (for the test script)
- `boto3` Python package

---

## Manual Deployment

### 1. Clone the repository

```bash
git clone https://github.com/Theo-Gkisis/aws-assesment.git
cd aws-assesment
```

### 2. Set variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set:
#   test_username      - Cognito test user email (e.g. user@example.com)
#   test_user_password - Cognito test user password (must meet Cognito password policy)
```

> **Password requirements:** Cognito enforces a strong password policy. Your `test_user_password` must be at least 8 characters and include uppercase letters, lowercase letters, numbers, and special characters (e.g. `MyP@ssw0rd!`).

### 3. Initialise Terraform

```bash
terraform init
```

### 4. Review the plan

```bash
terraform plan
```

### 5. Apply

```bash
terraform apply
```

Terraform will provision both regions in a single apply. Outputs include the API Gateway URLs for each region.

### 6. Tear down (important — avoid ongoing charges)

```bash
terraform destroy
```

---

## Running the Test Script

The script authenticates with Cognito, then concurrently calls `/greet` and `/dispatch` in both regions, asserting that each response contains the correct region identifier.

### Install dependencies

```bash
pip install boto3
```

### Set the test user credentials

The test script reads credentials from environment variables. Either export them:

```bash
export TEST_USERNAME="user@example.com"
export TEST_USER_PASSWORD="YourPassword123!"
```

Or create a `.env` file in the project root:

```
TEST_USERNAME=user@example.com
TEST_USER_PASSWORD=YourPassword123!
```

> These must match the values set in `terraform.tfvars` used during `terraform apply`.

### Run

```bash
python scripts/test_deployment.py
```

### Expected output

```
Reading Terraform outputs ...
  us-east-1 : https://<id>.execute-api.us-east-1.amazonaws.com/v1
  eu-west-1 : https://<id>.execute-api.eu-west-1.amazonaws.com/v1

Authenticating as theodorosgkisis@gmail.com ...
  JWT obtained  (2026-03-14T10:00:00+00:00)

Step 3 — POST /greet (both regions concurrently) ...

  [PASS]  us-east-1  —  HTTP 200  (210 ms)
         message   : Hello, theodorosgkisis@gmail.com! Greetings from us-east-1.
         region    : [PASS]  expected=us-east-1  got=us-east-1

  [PASS]  eu-west-1  —  HTTP 200  (310 ms)
         message   : Hello, theodorosgkisis@gmail.com! Greetings from eu-west-1.
         region    : [PASS]  expected=eu-west-1  got=eu-west-1

Step 4 — POST /dispatch (both regions concurrently) ...
  (triggers a Fargate task that publishes to SNS)

  [PASS]  us-east-1  —  HTTP 200  (180 ms)
         region    : [PASS]  expected=us-east-1  got=us-east-1
         task_arn  : arn:aws:ecs:us-east-1:123456789012:task/...
         arn_region: [PASS]  expected=us-east-1  got=us-east-1

  [PASS]  eu-west-1  —  HTTP 200  (290 ms)
         region    : [PASS]  expected=eu-west-1  got=eu-west-1
         task_arn  : arn:aws:ecs:eu-west-1:123456789012:task/...
         arn_region: [PASS]  expected=eu-west-1  got=eu-west-1

══════════════════════════════════════════════════
  RESULT: PASS — all endpoints OK in both regions.
```

---

## CI/CD Pipeline

The GitHub Actions workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)) runs four sequential jobs on every push to `main`:

| Job | Tool | Purpose |
|-----|------|---------|
| Lint & Validate | `terraform fmt`, `terraform validate` | Formatting and syntax checks — no credentials needed |
| Security Scan | Checkov | Static analysis for IaC misconfigurations |
| Plan | `terraform plan` | Infrastructure diff |
| Integration Tests | `python scripts/test_deployment.py` | Post-deploy endpoint validation (placeholder) |

### Integration Tests step — important note

The `integration-tests` job is a **post-deployment placeholder**. In this pipeline it runs after `plan` to demonstrate pipeline architecture. In a production workflow it would depend on a `deploy` (`terraform apply`) job:

```
lint-validate → security-scan → plan → deploy → integration-tests
```

The test script (`scripts/test_deployment.py`) requires live infrastructure to be deployed before it can run. It reads API Gateway URLs directly from `terraform output`, then authenticates with Cognito and hits both regions. **It must always be executed after a successful `terraform apply`**, either:

- **Locally** — run `terraform apply` first, then `python scripts/test_deployment.py`
- **In CI/CD** — configure a `deploy` job that runs `terraform apply` (with a remote backend for state persistence), then let `integration-tests` depend on it

The AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TEST_USER_PASSWORD`) are defined as secrets in the job so the pipeline architecture is complete and production-ready, even though no credentials are injected into this runner per the assessment spec.

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `TEST_USER_PASSWORD` | Cognito test user password |
| `SNS_TOPIC_ARN` | Unleash Live verification SNS topic ARN |
