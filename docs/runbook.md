# Security Operations Runbook

## Incident containment

1. Identify the account, region, VPC, workload, and suspected source.
2. Preserve evidence before changing access: CloudTrail events, VPC Flow Logs, GuardDuty findings, Config history, and workload logs.
3. Prefer a temporary, tagged security-group or NACL containment rule with an owner and expiry time. Do not edit Terraform state manually.
4. Revoke compromised sessions and rotate secrets through Secrets Manager or the owning identity provider.
5. Record the event, remediation, and follow-up control in the incident system.

## IAM review

- Review role trust policies monthly.
- Remove unused policies and access keys.
- Prefer permission boundaries and session tags for delegated provisioning.
- Verify GitHub OIDC subjects remain repository- and branch-specific.

## Network review

- Review security-group and NACL changes through pull requests.
- Reject `0.0.0.0/0` management access.
- Confirm NACL return paths, DNS, VPC endpoints, and ephemeral ports in staging.
- Verify flow logs are arriving and retained for at least 90 days.