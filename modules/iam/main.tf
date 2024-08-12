resource "aws_iam_role" "webhook_gateway_role" {
  name = "webhook_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs", aws_iam_policy.sns_publish_policy.arn]
}

resource "aws_iam_policy" "sns_publish_policy" {
  name = "api-gateway-sns-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish",
          "sns:ListTopics"
        ]
        Effect   = "Allow"
        Resource = var.sns_order_topic_arn
      },
    ]
  })
}
