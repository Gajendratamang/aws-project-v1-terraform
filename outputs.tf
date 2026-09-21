output "vpc_id" {
  description = "ID of the Project V1 VPC"
  value       = module.network.vpc_id
}

output "public_subnet_a_id" {
  description = "ID of Public Subnet A"
  value       = module.network.public_subnet_a_id
}

output "public_subnet_b_id" {
  description = "ID of Public Subnet B"
  value       = module.network.public_subnet_b_id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}


output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}