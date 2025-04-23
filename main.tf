provider "aws" {
  region = local.region
}

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
  private_subnets  = [cidrsubnet(local.vpc_cidr, 8, 2)]

  create_database_subnet_group = true
  create_igw = true
  create_multiple_public_route_tables = true

  enable_nat_gateway = true
  single_nat_gateway = true
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

module "ec2" {
  source = "./modules/ec2"

  key_name        = "user1"
  public_key_path = "~/.ssh/user1.pub"
  ami_id          = "ami-084568db4383264d4"
  instance_type   = "t2.medium"
  tags = {
    Environment = "prod"
    Owner       = "team-a"
  }

  instances = {
    Jenkins = {
      subnet_id                   = module.vpc.public_subnets[0]
      security_group_ids          = [module.security_groups.jenkins.security_group_id]
      associate_public_ip_address = true
      user_data_path              = "${path.module}/jenkins-user-data.sh"
    }
  }
}

module "ec2" {
  source = "./modules/ec2"

  key_name        = "user1"
  public_key_path = "~/.ssh/user1.pub"
  ami_id          = "ami-084568db4383264d4"
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
      user_data_path              = "${path.module}/gitlab-user-data.sh"
    }
  }
}
