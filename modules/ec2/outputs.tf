output "instance_ids" {
  description = "Map of instance IDs by name"
  value       = { for name, inst in module.ec2 : name => inst.id }
}

output "private_ips" {
  description = "Map of private IPs by name"
  value       = { for name, inst in module.ec2 : name => inst.private_ip }
}

output "public_ips" {
  description = "Map of public IPs by name (if assigned)"
  value       = { for name, inst in module.ec2 : name => inst.public_ip }
}

output "public_dns" {
  description = "Map of public DNS names by name (if assigned)"
  value       = { for name, inst in module.ec2 : name => inst.public_dns }
}
