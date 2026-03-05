 output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "ecr_user_service_url" {
  value = module.ecr.user_service_url
}

output "ecr_order_service_url" {
  value = module.ecr.order_service_url
}

output "ecr_product_service_url" {
  value = module.ecr.product_service_url
}

output "api_gateway_url" {
  value = module.api_gateway.api_url
}
