resource "aws_api_gateway_rest_api" "webhook_gateway" {
  name = "webhook_gateway"
}

resource "aws_api_gateway_resource" "commerce-engine" {
  parent_id   = aws_api_gateway_rest_api.webhook_gateway.root_resource_id
  path_part   = "commerce-engine"
  rest_api_id = aws_api_gateway_rest_api.webhook_gateway.id
}

resource "aws_api_gateway_resource" "orders" {
  parent_id   = aws_api_gateway_resource.commerce-engine.id
  path_part   = "orders"
  rest_api_id = aws_api_gateway_rest_api.webhook_gateway.id
}

resource "aws_api_gateway_method" "post-order-events" {
  rest_api_id      = aws_api_gateway_rest_api.webhook_gateway.id
  resource_id      = aws_api_gateway_resource.orders.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "order_topic_integration" {
  rest_api_id             = aws_api_gateway_rest_api.webhook_gateway.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.post-order-events.http_method
  credentials             = var.webhook_gateway_role_arn
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-1:sns:action/Publish"
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_MATCH"
  timeout_milliseconds    = 29000
  request_parameters = {
    "integration.request.querystring.Message" : "method.request.body.data"
    "integration.request.querystring.Subject" : "'order'"
    "integration.request.querystring.TopicArn" : "'${var.sns_order_topic_arn}'"
  }

}

# resource "aws_api_gateway_integration" "order_topic_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.webhook_gateway.id
#   resource_id             = aws_api_gateway_resource.orders.id
#   http_method             = aws_api_gateway_method.post-order-events.http_method
#   credentials             = var.webhook_gateway_role_arn
#   type                    = "AWS"
#   uri                     = "arn:aws:apigateway:us-east-1:sns:action/Publish"
#   integration_http_method = "POST"
#   passthrough_behavior    = "WHEN_NO_MATCH"
#   timeout_milliseconds    = 29000

#   request_templates = {
#     "application/json" = <<EOF
#       #set($inputRoot = $input.path('$'))
#   {
#     "Message": "$inputRoot.data",
#     "Subject": "order",
#     "TopicArn": "${var.sns_order_topic_arn}"
#   }
# EOF
#   }

# }

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.webhook_gateway.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post-order-events.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.webhook_gateway.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post-order-events.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

}


resource "aws_api_gateway_deployment" "webhook_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.webhook_gateway.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.orders,
      aws_api_gateway_method.post-order-events,
      aws_api_gateway_integration.order_topic_integration,
      aws_api_gateway_integration_response.MyDemoIntegrationResponse,
    ]))
  }

  depends_on = [aws_api_gateway_integration_response.MyDemoIntegrationResponse]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "webhook_gateway_dev_stage" {
  deployment_id = aws_api_gateway_deployment.webhook_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.webhook_gateway.id
  stage_name    = "dev"
  depends_on    = [aws_api_gateway_deployment.webhook_gateway_deployment]
}

