data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/authorizer"
  output_path = "${path.root}/../lambda/authorizer.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "authorizer" {
  filename         = data.archive_file.authorizer.output_path
  function_name    = "${var.project_name}-authorizer"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.authorizer.output_base64sha256

  environment {
    variables = {
      ENV = "production"
    }
  }

  tags = { Name = "${var.project_name}-authorizer" }
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
}