################################################################################
# EC2 Instance with SSM Access
################################################################################

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 5.0.0"

  name = "ssm-demo-instance"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.ec2_sg.security_group_id]
  key_name               = aws_key_pair.ssm_demo_key.key_name

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  tags = local.tags
}

################################################################################
# Security Group for EC2
################################################################################

module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.0.0"

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
# SSH Key Pair
################################################################################

resource "tls_private_key" "ssm_demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssm_demo_key" {
  key_name   = local.name
  public_key = tls_private_key.ssm_demo_key.public_key_openssh
}

output "ssm_private_key_pem" {
  description = "Private key for SSH access to the EC2 instance. Store this securely!"
  value       = tls_private_key.ssm_demo_key.private_key_pem
  sensitive   = true
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance created for SSM demo."
  value       = module.ec2_instance.id
}
