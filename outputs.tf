output "audit_bucket" { value = aws_s3_bucket.audit.id }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "app_security_group_id" { value = aws_security_group.app.id }
output "database_security_group_id" { value = aws_security_group.database.id }
output "github_deploy_role_arn" { value = try(aws_iam_role.github_deploy[0].arn, null) }