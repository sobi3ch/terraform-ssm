# EC2 Instance with SSM access
This Terraform configuration sets up an EC2 instance with SSM access, banning SSH access.

### Usage
1. Clone the repo & `cd` to it
1. Update setting in locals (optional)
1. `terraform init`
1. `terrafrom plan`
1. `terrafrom apply`

### Connect to instance via Session Manager over CLI
SSH to public instance. Get SSH key
```bash
terraform output -raw ssm_demo_private_key_pem > ssm-demo-key.pem
chmod 600 ssm-demo-key.pem
```

Get instance ID from the output
```bash
aws ssm start-session --target <instance-id>
```