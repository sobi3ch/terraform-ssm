# EC2 Instance with SSM access
This Terraform configuration sets up an EC2 instance with SSM access, banning SSH access.

### Usage
1. Clone the repo & `cd` to it
1. Update setting in locals (optional)
1. `terraform init`
1. `terrafrom plan`
1. `terrafrom apply`

### Connect to instance via Session Manager over CLI

Test connection with Session Manager 
```bash
aws ssm start-session --target $(terraform output -raw ec2_instance_id_private)
```