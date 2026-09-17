output "audit_bucket" { value = aws_s3_bucket.audit.id }
output "alb_security_group_id" { value = module.alb_security_group.security_group_id }
output "app_security_group_id" { value = module.app_security_group.security_group_id }
output "database_security_group_id" { value = module.database_security_group.security_group_id }
output "github_deploy_role_arn" { value = try(aws_iam_role.github_deploy[0].arn, null) }