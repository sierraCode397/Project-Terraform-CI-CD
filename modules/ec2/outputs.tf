output "instance_info" {
  description = "Map of instance connection details"
  value = {
    for name, inst in module.ec2 : name => {
      id          = inst.id
      private_ip  = inst.private_ip
      public_dns  = inst.public_dns
      public_ip   = inst.public_ip
    }
  }
}