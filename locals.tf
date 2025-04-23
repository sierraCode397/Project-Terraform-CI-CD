locals {
  name   = "DevOps"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-rds"
  }

  security_groups = {
    jenkins = {
      name        = "Jenkins-sg"
      description = "Security group allowing access on HTTP, HTTPS, SSH, and custom Node.js port"
      ingress = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          description = "SSH access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          description = "HTTP access"
          cidr_blocks = "0.0.0.0/0"
        },
        # Jenkins UI (HTTP)
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          description = "Jenkins web interface"
          cidr_blocks = "0.0.0.0/0"
        },
        # Jenkins agent (JNLP) port
        {
          from_port   = 50000
          to_port     = 50000
          protocol    = "tcp"
          description = "Jenkins agent JNLP port"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          description = "Allow all outbound traffic"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
    }
    gitlab = {
      name        = "Gitlab-sg"
      description = "Security group for Backend to the Database"
      ingress = [
        {
          from_port   = 2424
          to_port     = 2424
          protocol    = "tcp"
          description = "SSH access (custom port)"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          description = "SSH access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          description = "HTTPS access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          description = "HTTP access"
          cidr_blocks = "0.0.0.0/0"
        },
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          description = "Allow all outbound traffic"
          cidr_blocks = "0.0.0.0/0"
        },
      ]
    }
  }
}
