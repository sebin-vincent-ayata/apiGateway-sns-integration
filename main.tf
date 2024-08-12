provider "aws" {
  region = "us-east-1"
}

module "sns" {
    source = "./modules/sns"
}

module "apigateway" {
    source = "./modules/apigateway"
    sns_order_topic_arn=module.sns.order_event_topic_arn
    webhook_gateway_role_arn=module.iam.webhook_gateway_role_arn
}

module "iam" {
  source= "./modules/iam"
  sns_order_topic_arn=module.sns.order_event_topic_arn
}

