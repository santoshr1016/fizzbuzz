output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet" {
  value = aws_subnet.public
}

output "private_subnet" {
  value = aws_subnet.private
}

output "aws_sg_public" {
  value = aws_security_group.master-public-lb
}

output "aws_sg_private" {
  value = aws_security_group.master-private-lb
}

output "aws_sg_master" {
  value = aws_security_group.master
}

output "aws_sg_etcd" {
  value = aws_security_group.etcd
}

output "aws_sg_worker" {
  value = aws_security_group.worker
}