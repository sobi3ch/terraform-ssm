# EC2 Instance with SSM access
This Terraform configuration sets up an EC2 instance inside private subnet where only access is thought Systems Manager.

### Purpose
Just to prove, you don't need to have a bastion host, instance inside public subnet (with public IP), VPN or any other means to gain access to "disconnected" instance (with only private IP).

### Usage
1. Clone the repo & `cd` to it.
1. Copy `variables.auto.tfvars.example` to `variables.auto.tfvars` and update if needed.
1. `terraform init`
1. `terrafrom plan`
1. `terrafrom apply`

### Connect to instance via Session Manager over CLI

Test connection with Session Manager 
```bash
aws ssm start-session --target $(terraform output -raw ec2_instance_id_private)
```
