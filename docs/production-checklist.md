# Production Change Checklist

## Before plan

- [ ] Correct AWS account and region selected
- [ ] SSO/MFA session is active
- [ ] Remote backend and state lock are configured
- [ ] Production inputs are supplied through protected CI secrets, never committed
- [ ] Change ticket, owner, rollback plan, and maintenance window exist

## Before apply

- [ ] Terraform format, validate, and Checkov passed
- [ ] Plan reviewed by infrastructure and security owners
- [ ] No broad `0.0.0.0/0` management ingress
- [ ] NACL stateless return traffic and required DNS/VPC endpoint paths reviewed
- [ ] Logging, encryption, GuardDuty, Security Hub, and Config remain enabled
- [ ] Production environment approval granted

## After apply

- [ ] Terraform outputs and AWS Config status verified
- [ ] Flow logs are arriving
- [ ] Security findings reach the response channel
- [ ] Workload health checks pass
- [ ] Evidence attached to the change ticket