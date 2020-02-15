## AWS region's Availabililty Zones
data "aws_availability_zones" "available" {
  state = "available"
}

## Get local workstation's external IPv4 address
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = false

  tags =  {
    Name = "${var.project}-VPC",
    Project = var.project
    Owner = var.owner
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = var.availability_zones
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index + 11)
  tags = {
    Name      = "${var.project}-public-${count.index}"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = var.availability_zones
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index + 1)
  map_public_ip_on_launch = false

  tags = {
    Name      = "${var.project}-private-${count.index}"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}


# AWS Elastic IP addresses (EIP) for NAT Gateways
resource "aws_eip" "nat" {
  count = var.availability_zones

  vpc = true

  tags = {
    Name    = "${var.project}-eip-natgw-${count.index}"
    Project = var.project
    Owner   = var.owner
  }
}

# AWS NAT Gateways
resource "aws_nat_gateway" "natgw" {
  count = var.availability_zones

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name    = "${var.project}-natgw-${count.index}"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
    Owner   = var.owner
  }
}

# AWS Route Tables
## Public
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "${var.project}-rt-public"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }
}

## Private
resource "aws_route_table" "rt-private" {
  count  = var.availability_zones
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = {
    Name      = "${var.project}-rt-private"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}


# AWS Route Table Associations
## Public
resource "aws_route_table_association" "public-rtassoc" {
  count          = var.availability_zones
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.rt-public.id
}

## Private
resource "aws_route_table_association" "private-rtassoc" {
  count          = var.availability_zones
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.rt-private[count.index].id
}

# SecurityGroups
resource "aws_security_group" "master-public-lb" {
  name_prefix = "master-public-lb-"
  description = "Master-Public-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-public"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-private-lb" {
  source = "./mo"
  name_prefix = "master-private-lb-"
  description = "Master-Private-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-private"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "etcd" {
  name_prefix = "etcd-"
  description = "etcd"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-etcd"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master" {
  name_prefix = "k8s-master-"
  description = "K8s Master"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-master"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "k8s-worker-"
  description = "K8s Worker"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-worker"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

### MasterPublicLB
resource "aws_security_group_rule" "allow_ingress_workstation_on-master-public-lb_kubectl" {
  security_group_id = aws_security_group.master-public-lb.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "kubectl: Workstation - MasterPublicLB"
}

### MasterPrivateLB
resource "aws_security_group_rule" "allow_ingress_on_master-private-lb_kubeapi" {
  security_group_id = aws_security_group.master-private-lb.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "kubeapi: ALL - MasterPrivateLB"
}

### etcd
resource "aws_security_group_rule" "allow_etcd" {
  for_each = {
    "Masters" = aws_security_group.master.id,
    "Etcd"    = aws_security_group.etcd.id
  }
  security_group_id        = aws_security_group.etcd.id
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "etcd: ${each.key} - Etcds"
}

### Master
resource "aws_security_group_rule" "allow_kubectl_on_master" {
  for_each = {
    "MasterPublicLB"  = aws_security_group.master-public-lb.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id        = aws_security_group.master.id
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "kubectl: ${each.key} - Masters"
}

resource "aws_security_group_rule" "allow_ingress_worker_on_master_all" {
  security_group_id        = aws_security_group.master.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.worker.id
  description              = "ALL: Workers - Masters"
}

### Worker
resource "aws_security_group_rule" "allow_ingress_on_worker_all" {
  for_each = {
    "Masters"         = aws_security_group.master.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id
  }
  security_group_id        = aws_security_group.worker.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = each.value
  description              = "ALL: ${each.key} - Workers"
}

## Egress
resource "aws_security_group_rule" "egress_all" {
  for_each = {
    "MasterPublicLB"  = aws_security_group.master-public-lb.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Etcds"           = aws_security_group.etcd.id,
    "Masters"         = aws_security_group.master.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id = each.value
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Egress ALL: ${each.key}"
}

