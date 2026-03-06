# AWS Microservices E-Commerce Platform

A production-grade, cloud-native e-commerce backend built on AWS using a microservices architecture. Fully provisioned with Terraform and automated through CI/CD pipelines.

---

## Architecture Overview

```
                        ┌─────────────────┐
                        │   CloudFront    │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │   API Gateway   │  ← JWT Authorizer (Lambda)
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │ Application LB  │
                        └────────┬────────┘
                    ┌────────────┼────────────┐
                    │            │            │
             ┌──────▼─────┐ ┌───▼──────┐ ┌──▼───────────┐
             │User Service│ │  Order   │ │Product Service│
             │  (ECS)     │ │ Service  │ │   (ECS)       │
             └──────┬─────┘ │  (ECS)   │ └──────┬────────┘
                    │       └───┬──────┘         │
                    └───────────┼────────────────┘
                                │
                        ┌───────▼────────┐
                        │   RDS (MySQL)  │
                        └────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform |
| Cloud Provider | AWS |
| Container Orchestration | Amazon ECS (Fargate) |
| Container Registry | Amazon ECR |
| Load Balancing | Application Load Balancer |
| API Management | API Gateway |
| Authentication | AWS Lambda (JWT Authorizer) |
| Database | Amazon RDS |
| CDN | Amazon CloudFront |
| Frontend Hosting | Amazon S3 |
| CI/CD | AWS CodePipeline |
| Source Control | GitHub |

---

## Infrastructure Modules

The project is structured as reusable Terraform modules:

```
terraform/
├── main.tf                    # Root module — wires everything together
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/                   # VPC, subnets, routing
    ├── ecr/                   # Container registries (3 services)
    ├── ecs/                   # ECS cluster + Fargate services
    ├── alb/                   # Application Load Balancer + target groups
    ├── rds/                   # MySQL RDS instance
    ├── lambda/                # JWT authorizer function
    ├── api-gateway/           # REST API Gateway with auth
    ├── s3-cloudfront/         # Frontend hosting + CDN
    └── codepipeline/          # CI/CD pipeline
```

---

## Microservices

### User Service
Handles user registration, authentication, and profile management.
- **Endpoint:** `/users`
- **Container:** `ecommerce/user-service` (ECR)

### Order Service
Manages order creation, tracking, and history.
- **Endpoint:** `/orders`
- **Container:** `ecommerce/order-service` (ECR)

### Product Service
Manages product catalog, inventory, and search.
- **Endpoint:** `/products`
- **Container:** `ecommerce/product-service` (ECR)

---

## Key Features

- **Zero-trust API security** — Every request authenticated via Lambda JWT authorizer before reaching services
- **Auto-scaling** — ECS Fargate scales services independently based on load
- **Private networking** — Services run in private subnets, only ALB is public-facing
- **Immutable deployments** — CodePipeline builds new container images on every push, no in-place updates
- **Infrastructure as Code** — 100% of AWS resources defined in Terraform, no manual console changes

---

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.6
- Docker

### Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Push a Service Image

```bash
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS \
  --password-stdin 050763643556.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t ecommerce/user-service .
docker tag ecommerce/user-service:latest \
  050763643556.dkr.ecr.us-east-1.amazonaws.com/ecommerce/user-service:latest
docker push 050763643556.dkr.ecr.us-east-1.amazonaws.com/ecommerce/user-service:latest
```

CodePipeline will automatically detect the new image and deploy to ECS.

---

## Live Endpoints

| Resource | URL |
|---|---|
| API Gateway | `https://rqzegyx28d.execute-api.us-east-1.amazonaws.com/prod` |
| Load Balancer | `ecommerce-alb-878221187.us-east-1.elb.amazonaws.com` |

---

## What I Learned

- Designing multi-tier AWS architectures with proper network segmentation
- Writing modular, reusable Terraform at production scale
- Securing APIs with Lambda authorizers and JWT
- Building end-to-end CI/CD pipelines with CodePipeline and ECR
- Debugging Terraform state, module dependencies, and AWS IAM permission issues

---

## Author

**GY2AN** — learning DevOps by building real infrastructure.

GitHub: [github.com/GY2AN](https://github.com/GY2AN)
