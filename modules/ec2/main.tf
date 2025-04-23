module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"            # pin to a module version

  for_each = var.instances     # ← iterate over whatever the root gives you

  name                   = each.key
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  monitoring             = true
/*   ebs_block_device       = var.ebs_block_device */
  root_block_device      = var.root_block_device

  vpc_security_group_ids = each.value.security_group_ids
  subnet_id              = each.value.subnet_id
  associate_public_ip_address = each.value.associate_public_ip_address

  # only set user_data if provided
user_data = lookup(each.value, "user_data", null)

  tags = var.tags
}
