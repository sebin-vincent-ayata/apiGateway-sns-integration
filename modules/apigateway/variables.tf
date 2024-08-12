variable "sns_order_topic_arn" {
  description = "The ARN of the sns topic for Order Events"
  type        = string
}

variable "webhook_gateway_role_arn" {
  description = "The ARN of the IAM role for webhook gateway"
  type        = string
}