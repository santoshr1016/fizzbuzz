
variable "cidr" {
  description = "The CIDR of the VPC."
  default     = "10.0.0.0/16"
}

variable "project" {}
variable "owner" {}
variable "availability_zones" {}
variable "aws_key_pair_name" {}
variable "ssh_public_key_path" {}
