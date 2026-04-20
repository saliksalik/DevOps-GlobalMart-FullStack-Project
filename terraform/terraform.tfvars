# File: terraform/terraform.tfvars
# Edit these values before running terraform apply

aws_region       = "us-east-1"
environment      = "production"
instance_type    = "t3.micro"
instance_count   = 1
create_alb       = false
key_pair_name    = "globalmart-keypair"     # Must exist in your AWS account
allowed_ssh_cidr = "0.0.0.0/0"             # ⚠ Restrict to your IP in production!
