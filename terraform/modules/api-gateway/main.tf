# REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "E-Commerce API Gateway"

  tags = { Name = "${var.project_name}-api" }
}

# Lambda Authorizer
resource "aws_api_gateway_authorizer" "jwt" {
  name                   = "${var.project_name}-jwt-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.main.id
  authorizer_uri         = var.authorizer_invoke_arn
  authorizer_credentials = aws_iam_role.api_gateway_invoker.arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
}

# IAM Role for API Gateway to invoke Lambda
resource "aws_iam_role" "api_gateway_invoker" {
  name = "${var.project_name}-api-gateway-invoker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_invoker" {
  name = "${var.project_name}-api-gateway-invoker-policy"
  role = aws_iam_role.api_gateway_invoker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = var.authorizer_function_arn
    }]
  })
}

# ── /users resource ──
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "get_users" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt.id
}

resource "aws_api_gateway_integration" "get_users" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.users.id
  http_method             = aws_api_gateway_method.get_users.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/users"
}

# ── /orders resource ──
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "get_orders" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt.id
}

resource "aws_api_gateway_integration" "get_orders" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.get_orders.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/orders"
}

# ── /products resource ──
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt.id
}

resource "aws_api_gateway_integration" "get_products" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/products"
}

# Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_integration.get_users,
    aws_api_gateway_integration.get_orders,
    aws_api_gateway_integration.get_products
  ]

  lifecycle {
    create_before_destroy = true
  }
}