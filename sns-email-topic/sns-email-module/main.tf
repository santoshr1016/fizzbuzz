data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/templates/email-sns-stack.json.tpl")

  vars = {
    display_name  = var.sns_topic_display_name
    email_address = var.sns_subscription_email_address
    protocol      = var.sns_subscription_protocol
  }
}

resource "aws_cloudformation_stack" "sns-topic" {
  name          = var.stack_name
  template_body = data.template_file.cloudformation_sns_stack.rendered
  tags = {
      "Name" = var.stack_name
    }
}

