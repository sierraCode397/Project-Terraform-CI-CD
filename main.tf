provider "aws" {
  region = local.region
}

resource "aws_key_pair" "user1" {
  key_name   = "user1"
  public_key = file("~/.ssh/user1.pub")
}

data "aws_availability_zones" "available" {}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [cidrsubnet(local.vpc_cidr, 8, 0), cidrsubnet(local.vpc_cidr, 8, 1)]

  create_database_subnet_group = true
  create_igw = true
  create_multiple_public_route_tables = true

  enable_nat_gateway = false
  single_nat_gateway = false
  one_nat_gateway_per_az = false

  tags = local.tags
}

################################################################################
# Security Groups
################################################################################

module "security_groups" {
  for_each = local.security_groups

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = each.value.name
  description = each.value.description
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = each.value.ingress
  egress_with_cidr_blocks  = each.value.egress

  tags = local.tags
}

################################################################################
# EC2 Instances
################################################################################

module "ec2-jenkins" {
  source = "./modules/ec2"

  key_name        = aws_key_pair.user1.key_name
  ami_id          = "ami-084568db4383264d4"
  instance_type   = "t3.medium"
  tags = {
    Environment = "prod"
    Owner       = "team-a"
  }

  instances = {
    Jenkins = {
      subnet_id                   = module.vpc.public_subnets[0]
      security_group_ids          = [module.security_groups.jenkins.security_group_id]
      associate_public_ip_address = true
      user_data = file("${path.module}/user-data/jenkins-user-data.sh")
    }
  }
}

module "ec2-gitlab" {
  source = "./modules/ec2"

  key_name        = aws_key_pair.user1.key_name
  ami_id          = "ami-0c15e602d3d6c6c4a"
  instance_type   = "t3.medium"
  tags = {
    Environment = "prod"
    Owner       = "team-a"
  }

  instances = {
    Gitlab = {
      subnet_id                   = module.vpc.public_subnets[1]
      security_group_ids          = [module.security_groups.gitlab.security_group_id]
      associate_public_ip_address = true
      user_data = file("${path.module}/user-data/gitlab-user-data.sh")

/*      ebs_block_device = {
        volume_size = "30"
        volume_type = "gp3" # or "gp2" depending on what you prefer
      } */

      root_block_device = [
        {
          volume_size = 30
          volume_type = "gp3"
          delete_on_termination = true
        }
      ]
    }
  }
}
