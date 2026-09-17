# Threat Model

## Assets

- AWS identities and CI federation
- Application workloads and databases
- Audit logs and security findings
- Terraform state and deployment credentials

## Main threats and controls

| Threat | Primary controls |
| --- | --- |
| Leaked CI credential | GitHub OIDC, branch-bound trust, no static cloud keys |
| Public workload exposure | Layered security groups, NACLs, private subnets, no SSH rules |
| Lateral movement | Tier-specific security groups, restricted database ingress, flow logs |
| Evidence destruction | Versioned encrypted audit bucket and CloudWatch retention |
| Undetected compromise | GuardDuty, Security Hub, Config, CloudTrail integration |
| Accidental privilege escalation | Terraform plan review, resource-scoped IAM, separate security account |

## Residual risk

This repository cannot infer the correct application ports, routing, organization SCPs, DNS, identity provider, or data classification. Those must be reviewed by the environment owner before apply.