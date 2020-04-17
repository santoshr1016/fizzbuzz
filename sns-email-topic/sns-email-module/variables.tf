variable "sns_subscription_email_address" {
  type        = string
  description = "Email address to send notifications to"
}

variable "sns_subscription_protocol" {
  default     = "email"
  description = "SNS Protocol to use. email or email-json"
  type        = string
}

variable "sns_topic_name" {
   type = string
   description = "SNS topic name"
 }

variable "sns_topic_display_name" {
  type        = string
  description = "Name shown in confirmation emails"
  default     = "tf_sns_email"
}

variable "owner" {
  type        = string
  description = "Sets the owner tag on the CloudFormation stack"
  default     = "Santosh"
}

variable "stack_name" {
  type        = string
  description = "Cloudformation stack name that wraps the SNS topic. Must be unique."
  default     = "tf-sns-email-stack"
}