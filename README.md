# AWS Security Baseline

Least-privilege, infrastructure-as-code controls for an existing AWS VPC. This repository does not create a VPC, subnets, routes, NAT gateways, or application workloads. It protects the identifiers supplied in `terraform.tfvars`.

## Controls included

- IAM account password policy with length, complexity, rotation, and reuse prevention
- Optional GitHub Actions OIDC role restricted to one repository and the `main` branch
- No SSH ingress in the security groups
- ALB HTTPS ingress, app traffic only from the ALB security group, and PostgreSQL only from the app security group
- Public, private, and database subnet network ACLs
- VPC Flow Logs to CloudWatch Logs
- Encrypted, versioned, public-access-blocked audit S3 bucket
- EBS encryption by default
- GuardDuty and Security Hub
- AWS Config recorder and delivery channel

## Prerequisites

Use Terraform 1.6+, AWS CLI v2, and an AWS identity dedicated to provisioning. The identity needs permission to create the resources in the Terraform plan. Enable MFA for human identities and use short-lived credentials or OIDC in CI.

Configure credentials without placing keys in this repository:

```bash
aws configure sso
aws sso login --profile security-admin
export AWS_PROFILE=security-admin
```

## Plan and apply

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace every placeholder with real VPC, subnet, CIDR, and region values.
2. Run formatting, initialization, validation, and a plan:

   ```bash
   terraform fmt -check -recursive
   terraform init
   terraform validate
   terraform plan -out=tfplan
   ```

3. Review the plan with the network and security owners. Apply only after approval:

   ```bash
   terraform apply tfplan
   ```

4. Verify controls:

   ```bash
   aws guardduty list-detectors
   aws securityhub describe-hub
   aws ec2 describe-flow-logs --filter Name=resource-id,Values=YOUR_VPC_ID
   aws ec2 get-ebs-encryption-by-default
   ```

## GitHub Actions OIDC

Create or reference the GitHub OIDC provider ARN, then set `github_oidc_provider_arn` and `github_repository` in `terraform.tfvars`. The trust policy accepts only `repo:OWNER/REPOSITORY:ref:refs/heads/main`. Extend the deployment role with resource-specific permissions for the exact ECR repositories and cluster resources used by the application; do not replace it with `AdministratorAccess`.

## Network ACL warning

NACLs are stateless. Every allowed flow needs return traffic, ephemeral ports, DNS, package repositories, and any required VPC endpoint paths. Test in a non-production VPC first. Security groups are the primary workload control; use NACLs as a subnet boundary and emergency containment layer.

## Production checklist

- Use separate AWS accounts for production, non-production, and security tooling.
- Require MFA and prohibit long-lived IAM user access keys.
- Enable AWS Organizations SCPs for region restrictions, public S3 prevention, and root-user protections.
- Send CloudTrail organization trails and security findings to a separate security account.
- Configure alert routing for GuardDuty, Security Hub, Config, CloudTrail, and flow-log anomalies.
- Encrypt Terraform state with a dedicated S3 backend and DynamoDB locking; never use local state for shared production work.
- Run `terraform plan` in CI and require an approved pull request before apply.

## Scope

This is a baseline, not a certification or a substitute for AWS Well-Architected, CIS, PCI, HIPAA, or internal controls review. Inspect the plan and adapt rules to the actual application ports and subnet routing before applying.