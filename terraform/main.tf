terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region   # us-east-1 from variables.tf
}

# ── VPC: your private network in AWS ─────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "TaskFlow-VPC" }
}

# ── Public Subnet: where your EC2 will live ───────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "TaskFlow-Subnet" }
}

# ── Internet Gateway: connects VPC to internet ────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "TaskFlow-IGW" }
}

# ── Route Table: tells the subnet to route traffic through IGW ────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "TaskFlow-RT" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group: firewall rules ────────────────────────────────
resource "aws_security_group" "sg" {
  name        = "taskflow-sg"
  description = "TaskFlow firewall"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "TaskFlow-SG" }
}

# ── EC2 Instance ──────────────────────────────────────────────────
resource "aws_instance" "server" {
  # Ubuntu 22.04 LTS — us-east-1 (N. Virginia) — 2024
  # If this gives an error, go to EC2 → AMI Catalog → search Ubuntu 22.04 → copy latest ID
  ami = "ami-0c7217cdde317cfec"

  instance_type          = var.instance_type   # t3.large
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = var.key_name        # taskflow-key

  root_block_device {
    volume_size = 30      # 30GB — enough for Docker images + Jenkins + K8s
    volume_type = "gp3"
  }

  tags = { Name = "TaskFlow-Server" }
}

# ── Outputs printed after terraform apply ─────────────────────────
output "public_ip" {
  value = aws_instance.server.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/taskflow-key.pem ubuntu@${aws_instance.server.public_ip}"
}

output "app_url" {
  value = "http://${aws_instance.server.public_ip}"
}

output "jenkins_url" {
  value = "http://${aws_instance.server.public_ip}:8080"
}