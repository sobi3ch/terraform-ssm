################################################################################
# VPC Endpoints for SSM in private subnets
################################################################################
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ec2_sg.security_group_id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ec2_sg.security_group_id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.ec2_sg.security_group_id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
  tags              = local.tags
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

  name        = "ssm-demo-ec2-sg"
  description = "Allow SSM (443) and SSH (22)"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = "0.0.0.0/0" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = "0.0.0.0/0" }
  ]

  egress_with_cidr_blocks = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = "0.0.0.0/0" }
  ]

  tags = local.tags
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
