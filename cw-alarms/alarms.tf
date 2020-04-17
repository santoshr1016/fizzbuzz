resource "aws_sns_topic" "alarm" {
  name = "alarms-topic"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  }
}

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html#ec2-cloudwatch-metrics
resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  alarm_name                = "CPUUtilization-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions             = [ aws_sns_topic.alarm.arn ]

  dimensions {
    InstanceId = aws_instance.my-server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "DiskReadOps" {
  alarm_name                = "DiskReadOps-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "DiskReadOps"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 Completed read operations"
  alarm_actions             = [ aws_sns_topic.alarm.arn ]

  dimensions {
    InstanceId = aws_instance.my-server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "live-or-dead" {
  alarm_name                = "live-or-dead-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors ec2 live or dead"
  alarm_actions             = [ aws_sns_topic.alarm.arn ]

  dimensions {
    InstanceId = aws_instance.my-server.id
  }
}