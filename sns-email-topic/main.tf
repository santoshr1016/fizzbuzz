provider "aws" {
  region = "ap-southeast-1"
}

module "admin-sns-email-topic" {
  source = "./sns-email-module"
  sns_subscription_email_address = "santy1016@gmail.com"
  sns_topic_name = "MySampleTopic"
  stack_name = "santosh-test"
}