resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb"
  description = "Public HTTPS load balancer; no SSH access."
  vpc_id      = var.vpc_id
  ingress {
    description = "HTTPS from the internet"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { protocol = "-1" from_port = 0 to_port = 0 cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-app"
  description = "Application traffic only from the ALB."
  vpc_id      = var.vpc_id
  ingress {
    description     = "HTTP from the ALB"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
  }
  egress { protocol = "-1" from_port = 0 to_port = 0 cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "database" {
  name        = "${var.environment}-database"
  description = "Database traffic only from the application tier."
  vpc_id      = var.vpc_id
  ingress {
    description     = "PostgreSQL from application tier"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]
  }
  egress { protocol = "-1" from_port = 0 to_port = 0 cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
  tags       = { Name = "${var.environment}-public" }
  ingress { protocol = "tcp" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 80 to_port = 443 }
  ingress { protocol = "tcp" rule_no = 110 action = "allow" cidr_block = "0.0.0.0/0" from_port = 1024 to_port = 65535 }
  egress  { protocol = "-1" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 0 to_port = 0 }
}

resource "aws_network_acl" "private" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.environment}-private" }
  ingress { protocol = "tcp" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 1024 to_port = 65535 }
  egress  { protocol = "tcp" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 443 to_port = 443 }
  egress  { protocol = "tcp" rule_no = 110 action = "allow" cidr_block = "0.0.0.0/0" from_port = 1024 to_port = 65535 }
}

resource "aws_network_acl" "database" {
  vpc_id     = var.vpc_id
  subnet_ids = var.database_subnet_ids
  tags       = { Name = "${var.environment}-database" }
  ingress { protocol = "tcp" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 1024 to_port = 65535 }
  egress  { protocol = "tcp" rule_no = 100 action = "allow" cidr_block = "0.0.0.0/0" from_port = 1024 to_port = 65535 }
}