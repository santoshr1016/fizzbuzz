resource "aws_cloudwatch_event_rule" "EC2" {
  name        = "capture-ec2-changes"
  description = "Capture all EC2 event changes"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling",
    "aws.ec2"
  ],
  "detail-type": [
      "EC2 Instance Launch Successful",
      "EC2 Instance State-change Notification"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "asg_ec2" {
  rule      = aws_cloudwatch_event_rule.EC2.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_ec2_topic.arn
}

resource "aws_sns_topic" "aws_ec2_topic" {
  name = "aws-ec2-events"
    provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  }
}

resource "aws_sns_topic_policy" "asg_ec2_default" {
  arn    = aws_sns_topic.aws_ec2_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "asg_ec2_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.aws_ec2_topic.arn]
  }
}