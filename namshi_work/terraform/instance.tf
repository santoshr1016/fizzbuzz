data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k8sNode" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # the VPC subnet
  subnet_id = module.vpc.public_subnets[0]

  # the security group
  vpc_security_group_ids = aws_security_group.allow-ssh.id

  # the public SSH key
  key_name = aws_key_pair.mykeypair.key_name

}

resource "null_resource" "ConfigureAnsibleLabelVariable" {
  provisioner "local-exec" {
    command = "echo [${var.dev_host_label}:vars] > hosts"
  }
  provisioner "local-exec" {
    command = "echo ansible_ssh_user=${var.ssh_user_name} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo ansible_ssh_private_key_file=${var.ssh_key_path} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo [${var.dev_host_label}] >> hosts"
  }
}

resource "null_resource" "ProvisionRemoteHostsIpToAnsibleHosts" {
  count = var.instance_count
  connection {
    type = "ssh"
    user = var.ssh_user_name
    host = element(aws_instance.k8sNode.*.public_ip, count.index)
    private_key = file(var.ssh_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install python-setuptools python-pip -y",
      "sudo pip install httplib2"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${element(aws_instance.k8sNode.*.public_ip, count.index)} >> hosts"
  }
}

resource "null_resource" "ModifyApplyAnsiblePlayBook" {
  provisioner "local-exec" {
    command = "sed -i -e '/hosts:/ s/: .*/: ${var.dev_host_label}/' playbook/k8s.yml"
  }

  provisioner "local-exec" {
    command = "sleep 10; ansible-playbook -i hosts playbook/k8s.yml"
  }
  depends_on = ["null_resource.ProvisionRemoteHostsIpToAnsibleHosts"]
}

