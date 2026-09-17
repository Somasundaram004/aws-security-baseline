module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"
  name        = "${var.environment}-alb"
  description = "Public HTTPS load balancer; no SSH access."
  vpc_id      = var.vpc_id
  ingress_with_cidr_blocks = [{ from_port = 443, to_port = 443, protocol = "tcp", description = "HTTPS from the internet", cidr_blocks = "0.0.0.0/0" }]
  egress_rules = ["all-all"]
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"
  name        = "${var.environment}-app"
  description = "Application traffic only from the ALB."
  vpc_id      = var.vpc_id
  ingress_with_source_security_group_id = [{ from_port = 80, to_port = 80, protocol = "tcp", description = "HTTP from the ALB", source_security_group_id = module.alb_security_group.security_group_id }]
  egress_rules = ["all-all"]
}

module "database_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"
  name        = "${var.environment}-database"
  description = "Database traffic only from the application tier."
  vpc_id      = var.vpc_id
  ingress_with_source_security_group_id = [{ from_port = 5432, to_port = 5432, protocol = "tcp", description = "PostgreSQL from application tier", source_security_group_id = module.app_security_group.security_group_id }]
  egress_rules = ["all-all"]
}

resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
  tags       = { Name = "${var.environment}-public" }
}

resource "aws_network_acl" "private" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.environment}-private" }
}

resource "aws_network_acl" "database" {
  vpc_id     = var.vpc_id
  subnet_ids = var.database_subnet_ids
  tags       = { Name = "${var.environment}-database" }
}

resource "aws_network_acl_rule" "public_https" {
  network_acl_id = aws_network_acl.public.id
  egress = false
  rule_number = 100
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "public_http_redirect" {
  network_acl_id = aws_network_acl.public.id
  egress = false
  rule_number = 110
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "public_ephemeral_in" {
  network_acl_id = aws_network_acl.public.id
  egress = false
  rule_number = 120
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "public_all_out" {
  network_acl_id = aws_network_acl.public.id
  egress = true
  rule_number = 100
  protocol = "-1"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "private_ephemeral_in" {
  for_each = { for index, cidr in var.private_cidr_blocks : tostring(100 + index) => cidr }
  network_acl_id = aws_network_acl.private.id
  egress = false
  rule_number = each.key
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = each.value
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "private_https_out" {
  network_acl_id = aws_network_acl.private.id
  egress = true
  rule_number = 100
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "private_ephemeral_out" {
  network_acl_id = aws_network_acl.private.id
  egress = true
  rule_number = 110
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "database_postgres_in" {
  for_each = { for index, cidr in var.private_cidr_blocks : tostring(100 + index) => cidr }
  network_acl_id = aws_network_acl.database.id
  egress = false
  rule_number = each.key
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = each.value
  from_port = 5432
  to_port = 5432
}

resource "aws_network_acl_rule" "database_ephemeral_in" {
  for_each = { for index, cidr in var.private_cidr_blocks : tostring(200 + index) => cidr }
  network_acl_id = aws_network_acl.database.id
  egress = false
  rule_number = each.key
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = each.value
  from_port = 1024
  to_port = 65535
}

resource "aws_network_acl_rule" "database_ephemeral_out" {
  for_each = { for index, cidr in var.private_cidr_blocks : tostring(100 + index) => cidr }
  network_acl_id = aws_network_acl.database.id
  egress = true
  rule_number = each.key
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = each.value
  from_port = 1024
  to_port = 65535
}