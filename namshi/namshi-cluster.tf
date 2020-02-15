## Ubuntu AMI for all K8s instances
module "vpc" {
  project = var.project
  owner = var.owner
  availability_zones = var.availability_zones
  aws_key_pair_name = var.aws_key_pair_name
  ssh_public_key_path = var.ssh_public_key_path
  source = "./modules/vpc"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "ssh" {
  count      = var.aws_key_pair_name == null ? 1 : 0
  key_name   = "${var.owner}-${var.project}"
  public_key = file(var.ssh_public_key_path)
}

## Kubernetes Master (for remote kubctl access from workstation)
resource "aws_elb" "master-public" {
  name_prefix     = "master" // cannot be longer than 6 characters
  subnets         = module.vpc.public_subnet.*.id
  security_groups = [module.vpc.aws_sg_public.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  tags = {
    Name      = "${var.project}-master--publiclb"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }
}

## Kubernetes Master (fronting kube-apiservers)
resource "aws_elb" "master-private" {
  name_prefix     = "master" // will be prefixed with internal -  cannot be longer than 6 characters
  internal        = true
  subnets         = module.vpc.private_subnet.*.id
  security_groups = [module.vpc.aws_sg_private.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  tags = {
    Name     = "${var.project}-master--private-lb"
    ttribute = "private"
    Project  = var.project
    Owner    = var.owner
  }
}

## etcd
resource "aws_launch_configuration" "etcd" {
  name_prefix                 = "etcd-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.etcd_instance_type
  security_groups             = [module.vpc.aws_sg_etcd.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/userdata.tpl", {
    domain = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## Kubernetes Master
resource "aws_launch_configuration" "master" {
  name_prefix                 = "master-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  security_groups             = [module.vpc.aws_sg_master.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/userdata.tpl", {
    domain = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## Kubernetes Worker
resource "aws_launch_configuration" "worker" {
  name_prefix                 = "worker-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  security_groups             = [module.vpc.aws_sg_worker.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/userdata-worker.tpl", {
    pod_cidr = var.pod_cidr
    domain   = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## etcd
resource "aws_autoscaling_group" "etcd" {
  max_size             = var.etcd_max_size
  min_size             = var.etcd_min_size
  desired_capacity     = var.etcd_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.etcd.name
  vpc_zone_identifier  = module.vpc.private_subnet.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-etcd"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }
  ]
}

## Kubernetes Master
resource "aws_autoscaling_group" "master" {
  max_size             = var.master_max_size
  min_size             = var.master_min_size
  desired_capacity     = var.master_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.master.name
  vpc_zone_identifier  = module.vpc.private_subnet.*.id
  load_balancers       = [aws_elb.master-public.id, aws_elb.master-private.id]

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-k8s-master"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }
  ]
}

## Kubernetes Worker
resource "aws_autoscaling_group" "worker" {
  max_size             = var.worker_max_size
  min_size             = var.worker_min_size
  desired_capacity     = var.worker_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.worker.name
  vpc_zone_identifier  = module.vpc.private_subnet.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-k8s-worker"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }
  ]
}

## Kubernetes Master for remote kubectl access
resource "aws_route53_record" "master_lb-public" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "kube"
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_elb.master-public.dns_name
    zone_id                = aws_elb.master-public.zone_id
  }
}



