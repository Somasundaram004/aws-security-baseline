# End-to-End Security Architecture

This diagram shows how identity, deployment, network enforcement, encryption, logging, detection, and response work together. The Terraform in this repository protects an existing VPC; it does not create the VPC or workload compute. ALB, application, and database security groups use the pinned public `terraform-aws-modules/security-group/aws` module; NACLs remain local resources.

```mermaid
flowchart TB
    human[Engineer with MFA and SSO]
    pr[Pull request and protected review]
    gh[GitHub Actions]
    oidc[GitHub OIDC federation]
    role[IAM Terraform role<br/>repository and branch restricted]
    plan[Terraform plan artifact]
    approval[Protected production approval]
    apply[Terraform apply]

    internet[Internet client]
    alb[Public ALB<br/>HTTPS only]
    albsg[ALB security group<br/>TCP 443]
    publicnacl[Public subnet NACL<br/>HTTPS, HTTP redirect,<br/>ephemeral return]
    app[Application workload]
    appsg[Application security group<br/>source: ALB SG only]
    privatenacl[Private subnet NACL<br/>private CIDRs and egress]
    db[Database]
    dbsg[Database security group<br/>TCP 5432 from app SG]
    dbnacl[Database subnet NACL<br/>TCP 5432 from app CIDRs]

    flow[VPC Flow Logs]
    cw[CloudWatch Logs]
    audit[Encrypted versioned audit S3]
    gd[GuardDuty]
    sh[Security Hub]
    config[AWS Config]
    response[Security team<br/>triage and containment]
    ebs[EBS encryption by default]

    human --> pr --> gh --> oidc --> role --> plan --> approval --> apply
    apply -. manages .-> albsg
    apply -. manages .-> appsg
    apply -. manages .-> dbsg
    apply -. manages .-> publicnacl
    apply -. manages .-> privatenacl
    apply -. manages .-> dbnacl
    apply -. enables .-> gd
    apply -. enables .-> sh
    apply -. enables .-> config

    internet --> alb
    alb --> albsg --> publicnacl --> app
    app --> appsg --> privatenacl --> db
    db --> dbsg --> dbnacl

    publicnacl -. traffic .-> flow
    privatenacl -. traffic .-> flow
    dbnacl -. traffic .-> flow
    flow --> cw
    flow --> audit
    gd --> sh
    config --> sh
    cw --> response
    audit --> response
    sh --> response
    ebs -. protects data at rest .-> app
    ebs -. protects data at rest .-> db

    classDef identity fill:#e8f1ff,stroke:#2457a6,color:#102a56
    classDef network fill:#eaf8ef,stroke:#237a44,color:#123d23
    classDef security fill:#fff2df,stroke:#a65b00,color:#5b3100
    classDef operations fill:#f4eaff,stroke:#6b3fa0,color:#352050
    class human,pr,gh,oidc,role,plan,approval,apply identity
    class internet,alb,albsg,publicnacl,app,appsg,privatenacl,db,dbsg,dbnacl network
    class flow,cw,audit,gd,sh,config,response,ebs security
```

## Request path

1. A client reaches the ALB over HTTPS.
2. The ALB security group permits TCP 443 from the internet. No SSH rule is created.
3. The public NACL permits the required listener and return traffic.
4. The application security group permits traffic only from the ALB security group.
5. The private NACL limits subnet traffic and egress paths.
6. The database security group permits PostgreSQL only from the application security group.
7. The database NACL additionally permits PostgreSQL only from declared private application CIDRs.

Security groups are stateful. NACLs are stateless, so both request and return paths must be explicitly allowed.

## Control and evidence path

1. GitHub Actions authenticates through OIDC; no long-lived AWS key is required.
2. Terraform creates a plan artifact before apply.
3. A protected production environment requires approval before the exact plan is applied.
4. EBS, S3 audit storage, and Terraform state use encryption controls.
5. VPC Flow Logs and CloudWatch preserve network evidence.
6. GuardDuty and Config findings feed Security Hub.
7. The security team triages findings and uses temporary, tracked containment rules before permanent Terraform remediation.

## Failure boundaries

- A missing readiness or health signal must stop an application rollout.
- A failed Terraform plan must block apply.
- A missing production approval must block apply.
- A NACL rule change must be tested for DNS, VPC endpoints, NAT return traffic, and application health before production.
- Findings and logs must be retained outside the workload account when organizational controls require independent evidence.