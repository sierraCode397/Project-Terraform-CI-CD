resource "aws_key_pair" "user1" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"            # pin to a module version

  for_each = var.instances     # ← iterate over whatever the root gives you

  name                   = each.key
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.user1.key_name
  monitoring             = true

  vpc_security_group_ids = each.value.security_group_ids
  subnet_id              = each.value.subnet_id
  associate_public_ip_address = each.value.associate_public_ip_address

  # only set user_data if provided
user_data = (
  lookup(each.value, "user_data_path", "") != ""
    ? file(each.value.user_data_path)
    : null
)

  tags = var.tags
}
