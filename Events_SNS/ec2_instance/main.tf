provider "aws" {
  region = "ap-southeast-1"
}
module "my_sns_module" {
  source = "../sns_alert"
}

resource "aws_instance" "test_instance" {
  ami           = "ami-09a4a9ce71ff3f20b"
  instance_type = "t2.micro"
  key_name      = "cfn-key1"
  tags = {
    Name = "Cloudwatch-101"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu-utilization" {
  alarm_name          = "high-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [module.my_sns_module.sns_topic]

  dimensions = {
    InstanceId = aws_instance.test_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "instance-health-check" {
  alarm_name          = "instance-health-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 health status"
  alarm_actions       = [module.my_sns_module.sns_topic]

  dimensions = {
    InstanceId = aws_instance.test_instance.id
  }
}
