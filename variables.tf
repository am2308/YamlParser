variable "resource_names_prefix" {
  type        = string
  description = "Prefix given to all resources e.g. os-api will set os-api-ec2 for the EC2 deployment."
  default     = "test"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to be applied to some resources."
  default     = {}
}
