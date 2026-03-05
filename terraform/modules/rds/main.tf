# DB Subnet Group (needs 2 AZs)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]  # Only ECS can reach the DB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# RDS PostgreSQL (db.t3.micro = FREE TIER)
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"  # FREE TIER!
  allocated_storage = 20             # 20GB = FREE TIER limit
  storage_type      = "gp2"

  db_name  = "ecommerce"
  username = "ecommerce_user"
  password = "ChangeMe123!"  # In production: use Secrets Manager

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false  # Keep false to stay in free tier
  publicly_accessible = false
  skip_final_snapshot = true  # For easy cleanup

  tags = { Name = "${var.project_name}-db" }
}