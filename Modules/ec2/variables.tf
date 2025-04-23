variable "key_name" {
  description = "Name of the AWS key pair to use for all instances."
  type        = string
}

variable "public_key_path" {
  description = "Local path to the SSH public key for the key pair."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to launch for each EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type (e.g. t2.micro, t2.medium)."
  type        = string
  default     = "t2.micro"
}

variable "tags" {
  description = "A map of tags to apply to all EC2 instances."
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "instances" {
  description = <<EOF
Map of EC2 instance definitions.  
Key = an arbitrary name for the instance (used in for_each),  
Value = an object with:
  - subnet_id                   = the subnet to launch into  
  - security_group_ids          = list of SG IDs to attach  
  - associate_public_ip_address = whether to assign a public IP  
  - user_data_path (optional)   = path to a user_data script  
EOF

  type = map(object({
    subnet_id                   = string
    security_group_ids          = list(string)
    associate_public_ip_address = bool
    user_data_path              = optional(string)
  }))

  # Example default—remove or override in your root module
  default = {}
}
