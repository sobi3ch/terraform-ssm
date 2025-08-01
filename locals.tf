locals {
  name   = "${var.name}-${basename(path.cwd)}"
  region = var.region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "sobi3ch/terraform-ssm"
    ManagedBy  = "Terraform"
  }
}
