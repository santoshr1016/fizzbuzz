resource "aws_cloudwatch_event_rule" "apigateway" {
  name        = "capture-all-api-gateway-events"
  description = "Capture all API Gateway events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "api_gw" {
  rule      = aws_cloudwatch_event_rule.apigateway.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_api_gw_topic.arn
}

resource "aws_sns_topic" "aws_api_gw_topic" {
  name = "aws-api-gateway"

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  }
}

resource "aws_sns_topic_policy" "api_gw_pol" {
  arn    = aws_sns_topic.aws_api_gw_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "api_gw_pol_doc" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.aws_api_gw_topic.arn]
  }
}