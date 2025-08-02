data "aws_availability_zones" "available" {}


################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.0.0"

  name = local.name
  cidr = local.vpc_cidr

  enable_dns_hostnames = true

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]

  tags = local.tags
}
