# Production Security Training

This track trains operators to move the baseline from a disposable lab into a controlled production account. Complete the exercises in order and record evidence in the change ticket. Never use production credentials in a training account.

## Learning objectives

By the end of the track, an operator can explain least privilege, validate security-group and NACL paths, federate GitHub Actions without static keys, inspect GuardDuty/Security Hub/Config evidence, and perform an approved rollback.

## Stage 0: account and safety setup

Use three AWS accounts: `security`, `non-production`, and `production`. Protect the production account with an organization management process, an SCP baseline, MFA, and a break-glass role stored outside normal developer access.

Create the remote Terraform backend before this repository is used by a team:

```bash
aws s3api create-bucket --bucket COMPANY_STATE_BUCKET --region us-east-1 --create-bucket-configuration LocationConstraint=us-east-1
aws s3api put-bucket-versioning --bucket COMPANY_STATE_BUCKET --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket COMPANY_STATE_BUCKET --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws dynamodb create-table --table-name COMPANY_LOCK_TABLE --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

Review the commands with the cloud owner; names and regions must be unique to the organization. Configure `backend.hcl` from `backend.hcl.example`, then initialize with `terraform init -backend-config=backend.hcl`.

## Stage 1: lab exercise

1. Apply `terraform.tfvars.example` in a disposable VPC.
2. Confirm the ALB security group has only HTTPS ingress.
3. Confirm the application group accepts traffic only from the ALB group.
4. Confirm the database group accepts PostgreSQL only from the application group.
5. Use `aws ec2 describe-network-acls` to inspect stateless return paths.
6. Generate a test GuardDuty finding and verify it reaches the security team workflow.

## Stage 2: production rehearsal

1. Create a pull request changing only protected production inputs.
2. Review `terraform plan` with platform and security owners.
3. Verify that the plan does not replace subnets, change route tables, open SSH, or remove logging.
4. Apply in a maintenance window through the protected production environment.
5. Run the verification checklist and attach outputs to the change ticket.

## Stage 3: incident drill

Simulate a compromised workload source CIDR. Preserve logs, add a temporary containment rule with an expiry, verify the service impact, rotate credentials, and remove the temporary rule through Terraform. The drill is complete only when evidence, owner, and follow-up action are recorded.

## Pass criteria

- No IAM user access keys are used by CI.
- Every Terraform apply has an approved plan artifact.
- `terraform validate` and Checkov pass.
- GuardDuty, Security Hub, Config, and flow logs are enabled and alert routes are tested.
- Security-group and NACL rules have an owner, business purpose, and review date.
- A rollback path has been rehearsed in non-production.