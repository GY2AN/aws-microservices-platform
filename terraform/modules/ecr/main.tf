resource "aws_ecr_repository" "user_service" {
  name                 = "${var.project_name}/user-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allows destroying even with images (for learning)

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project_name}-user-service" }
}

resource "aws_ecr_repository" "order_service" {
  name                 = "${var.project_name}/order-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project_name}-order-service" }
}

resource "aws_ecr_repository" "product_service" {
  name                 = "${var.project_name}/product-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project_name}-product-service" }
}

# Lifecycle policy to keep only last 5 images (saves storage)
resource "aws_ecr_lifecycle_policy" "user_service" {
  repository = aws_ecr_repository.user_service.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}