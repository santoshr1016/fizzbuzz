variable "aws_region" {
    default = "us-east-1"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "instance_name" {
    default = "terra-ansible"
}

variable "ssh_user_name" {
    default = "ubuntu"
}

variable "ssh_key_path" {
    default = "~/.ssh/mykey.pem"
}

variable "instance_count" {
    default = 1
}

variable "dev_host_label" {
    default = "terra_ansible_host"
}