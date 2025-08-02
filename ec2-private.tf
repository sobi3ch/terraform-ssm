################################################################################
# Security Group for SSM endpionts in private subnets
################################################################################
module "ssm_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.0"

  name        = "ssm"
  description = "Security group for EC2 instance with SSM access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    for cidr in module.vpc.private_subnets_cidr_blocks : {
      description = "Allow HTTPS access to SSM endpoints"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = cidr
    }
  ]

  egress_with_cidr_blocks = []

  tags = merge(local.tags, { Name = "ssm-sg" })
}

################################################################################
# VPC Endpoints for SSM in private subnets
################################################################################
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ssm_sg.security_group_id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "ssm" })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ssm_sg.security_group_id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "ssmmessages" })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ssm_sg.security_group_id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "ec2messages" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
  tags              = merge(local.tags, { Name = "s3" })
}


################################################################################
# Latest Amazon Linux 2 AMI
################################################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# Security Group for EC2 Instance
################################################################################
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.0"

  name        = "ec2"
  description = "Security group for EC2 instance with SSM access"
  vpc_id      = module.vpc.vpc_id

  egress_cidr_blocks = ["10.10.0.0/16"]
  egress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.ssm_sg.security_group_id
    }
  ]

  tags = merge(local.tags, { Name = "ec2-sg" })
}

################################################################################
# IAM Role and Instance Profile for SSM
################################################################################
resource "aws_iam_role" "ssm_instance_role" {
  name = "ssm-demo-instance-role"

  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role_policy.json
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-demo-instance-profile"
  role = aws_iam_role.ssm_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
# IAM Assume Role Policy
################################################################################
data "aws_iam_policy_document" "ssm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

################################################################################
# EC2 Instance in Private Subnet with SSM Access
################################################################################
module "ec2_instance_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 5.0.0"

  name = "ssm-demo-private-instance"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  create_security_group  = false # Do not custom security group
  vpc_security_group_ids = [module.ec2_sg.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  depends_on = [
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages,
    aws_vpc_endpoint.s3
  ]

  tags = local.tags
}

################################################################################
# SSH Key Pair
################################################################################

output "ec2_instance_id_private" {
  description = "ID of the EC2 instance created for SSM demo."
  value       = module.ec2_instance_private.id
}
