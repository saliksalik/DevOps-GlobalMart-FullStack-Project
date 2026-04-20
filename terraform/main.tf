# ──────────────────────────────────────────────────────────────────────────────
# File: terraform/main.tf
# Purpose: Provision AWS infrastructure for GlobalMart K8s cluster
# Run:
#   terraform init
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — store tfstate in S3 (recommended for teams)
  # Uncomment after creating the S3 bucket manually
  # backend "s3" {
  #   bucket = "globalmart-terraform-state"
  #   key    = "production/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# ── Provider ─────────────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GlobalMart"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}


# ── Variables ─────────────────────────────────────────────────────────────────
variable "aws_region"         { default = "us-east-1" }
variable "environment"        { default = "production" }
variable "instance_type"      { default = "t3.micro" }
variable "instance_count"     { type = number default = 1 }
variable "create_alb"         { type = bool default = false }
variable "key_pair_name"      { description = "Name of your AWS EC2 Key Pair" }
variable "allowed_ssh_cidr"   { default = "0.0.0.0/0" ; description = "Restrict to your IP in prod!" }


# ── Data Sources ──────────────────────────────────────────────────────────────
data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ── VPC & Networking ──────────────────────────────────────────────────────────
resource "aws_vpc" "globalmart_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "globalmart-vpc-${var.environment}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.globalmart_vpc.id
  tags   = { Name = "globalmart-igw" }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.globalmart_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "globalmart-public-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.globalmart_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ── Security Groups ───────────────────────────────────────────────────────────
resource "aws_security_group" "globalmart_sg" {
  name        = "globalmart-sg-${var.environment}"
  description = "GlobalMart application security group"
  vpc_id      = aws_vpc.globalmart_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # App port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "GlobalMart API"
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Prometheus (internal)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ── EC2 Instances ─────────────────────────────────────────────────────────────
resource "aws_instance" "globalmart_server" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.globalmart_sg.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  # Bootstrap script — installs Docker on first boot
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
    echo "GlobalMart server ready: $(hostname)" > /tmp/setup.log
  EOF
  )

  tags = {
    Name = "globalmart-server-${count.index + 1}"
    Role = count.index == 0 ? "primary" : "secondary"
  }
}


# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "globalmart_alb" {
  count              = var.create_alb ? 1 : 0
  name               = "globalmart-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.globalmart_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "globalmart_tg" {
  count    = var.create_alb ? 1 : 0
  name     = "globalmart-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.globalmart_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "servers" {
  count            = var.create_alb ? var.instance_count : 0
  target_group_arn = aws_lb_target_group.globalmart_tg[0].arn
  target_id        = aws_instance.globalmart_server[count.index].id
  port             = 3000
}

resource "aws_lb_listener" "http" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.globalmart_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.globalmart_tg[0].arn
  }
}


# ── Outputs ───────────────────────────────────────────────────────────────────
output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.globalmart_alb[0].dns_name : ""
}

output "server_public_ips" {
  description = "Public IPs of GlobalMart EC2 instances"
  value       = aws_instance.globalmart_server[*].public_ip
}

output "ansible_inventory" {
  description = "Paste this into ansible/inventory.ini"
  value = join("\n", [
    for i, inst in aws_instance.globalmart_server :
    "web-server-0${i + 1} ansible_host=${inst.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_pair_name}.pem"
  ])
}
