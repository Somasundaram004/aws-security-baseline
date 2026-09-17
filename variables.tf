variable "aws_region" {
  type        = string
  description = "AWS region for regional controls."
}

variable "environment" {
  type        = string
  description = "Environment name used in resource names and tags."
  default     = "security-baseline"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC to protect. This project does not create a VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs that need a public NACL."
  default     = []
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs that need an application NACL."
  default     = []
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "Database subnet IDs that need a restrictive NACL."
  default     = []
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "Trusted private CIDRs for internal traffic."
  default     = []
}

variable "database_cidr_blocks" {
  type        = list(string)
  description = "Database subnet CIDRs used by NACL rules."
  default     = []
}

variable "allowed_admin_cidrs" {
  type        = list(string)
  description = "Explicit administrator CIDRs allowed to reach management ports. Keep narrow."
  default     = []
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = true
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub Actions OIDC provider ARN. Leave empty to skip the role."
  default     = ""
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repository allowed to assume the deploy role."
  default     = ""
}