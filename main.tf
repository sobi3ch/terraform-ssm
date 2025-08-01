provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "test-${basename(path.cwd)}"
  region = "eu-north-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.0.0"

  name = local.name
  cidr = local.vpc_cidr

  enable_nat_gateway = true
  single_nat_gateway = true

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 4)]

  tags = local.tags
}
