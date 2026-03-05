# Get latest ECS-optimized AMI (automatically stays up to date)
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# IAM Role for EC2 ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group for ECS EC2 instances
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = var.vpc_id

  # Allow ALL traffic from ALB (ephemeral ports for bridge networking)
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  # Allow all outbound (for pulling images from ECR, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-sg" }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project_name}-cluster" }
}

# Launch Template for EC2 ECS instances (t2.micro = FREE TIER)
resource "aws_launch_template" "ecs_ec2" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = "t2.micro"  # FREE TIER!

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  # This registers the EC2 instance with our ECS cluster
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-ecs-instance" }
  }
}

# Auto Scaling Group (manages the EC2 instances)
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-ecs-asg"
  vpc_zone_identifier = var.public_subnets  # Public subnet = no NAT Gateway needed!
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# ECS Capacity Provider (connects ASG to ECS cluster)
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.project_name}-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    base              = 1
    weight            = 100
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/${var.project_name}/user-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/${var.project_name}/order-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/ecs/${var.project_name}/product-service"
  retention_in_days = 7
}

# Task Definition: User Service
resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.project_name}-user-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"  # bridge = no NAT Gateway needed!
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  cpu                      = 256
  memory                   = 200

  container_definitions = jsonencode([{
    name  = "user-service"
    image = "${var.ecr_user_url}:latest"
    portMappings = [{
      containerPort = 3000
      hostPort      = 0  # 0 = dynamic port (bridge networking)
      protocol      = "tcp"
    }]
    environment = [
      { name = "PORT", value = "3000" },
      { name = "NODE_ENV", value = "production" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}/user-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
    essential = true
  }])
}

# Task Definition: Order Service
resource "aws_ecs_task_definition" "order_service" {
  family                   = "${var.project_name}-order-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  cpu                      = 256
  memory                   = 200

  container_definitions = jsonencode([{
    name  = "order-service"
    image = "${var.ecr_order_url}:latest"
    portMappings = [{ containerPort = 3001, hostPort = 0, protocol = "tcp" }]
    environment  = [{ name = "PORT", value = "3001" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}/order-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
    essential = true
  }])
}

# Task Definition: Product Service
resource "aws_ecs_task_definition" "product_service" {
  family                   = "${var.project_name}-product-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  cpu                      = 256
  memory                   = 200

  container_definitions = jsonencode([{
    name  = "product-service"
    image = "${var.ecr_product_url}:latest"
    portMappings = [{ containerPort = 5000, hostPort = 0, protocol = "tcp" }]
    environment  = [{ name = "PORT", value = "5000" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}/product-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
    essential = true
  }])
}

# ECS Services
resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.user_tg_arn
    container_name   = "user-service"
    container_port   = 3000
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}

resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.order_tg_arn
    container_name   = "order-service"
    container_port   = 3001
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}

resource "aws_ecs_service" "product_service" {
  name            = "product-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.product_service.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.product_tg_arn
    container_name   = "product-service"
    container_port   = 5000
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}