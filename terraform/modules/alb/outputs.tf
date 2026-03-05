output "alb_dns_name" { value = aws_lb.main.dns_name }
output "alb_arn" { value = aws_lb.main.arn }
output "alb_sg_id" { value = aws_security_group.alb.id }
output "listener_arn" { value = aws_lb_listener.http.arn }
output "user_tg_arn" { value = aws_lb_target_group.user.arn }
output "order_tg_arn" { value = aws_lb_target_group.order.arn }
output "product_tg_arn" { value = aws_lb_target_group.product.arn }