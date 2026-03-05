 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6"
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# ECR Repositories
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# ALB
module "alb" {
  source          = "./modules/alb"
  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
}

# RDS
module "rds" {
  source           = "./modules/rds"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnet_ids
  ecs_sg_id        = module.ecs.ecs_sg_id
}

# ECS Cluster + Services
module "ecs" {
  source              = "./modules/ecs"
  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  alb_sg_id           = module.alb.alb_sg_id
  user_tg_arn         = module.alb.user_tg_arn
  order_tg_arn        = module.alb.order_tg_arn
  product_tg_arn      = module.alb.product_tg_arn
  ecr_user_url        = module.ecr.user_service_url
  ecr_order_url       = module.ecr.order_service_url
  ecr_product_url     = module.ecr.product_service_url
}

module "codepipeline" {
  source           = "./modules/codepipeline"
  project_name     = var.project_name
  ecr_registry     = "050763643556.dkr.ecr.us-east-1.amazonaws.com"
  github_repo      = "GY2AN/aws-microservices-platform"
  ecs_cluster_name = module.ecs.cluster_name
}

module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
}

module "api_gateway" {
  source                  = "./modules/api-gateway"
  project_name            = var.project_name
  alb_dns_name            = module.alb.alb_dns_name
  authorizer_invoke_arn   = module.lambda.authorizer_invoke_arn
  authorizer_function_arn = "arn:aws:lambda:us-east-1:050763643556:function:ecommerce-authorizer"
}

module "s3_cloudfront" {
  source       = "./modules/s3-cloudfront"
  project_name = var.project_name
}
