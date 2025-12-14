output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.Konvert_ALB.dns_name
}

output "ec2_public_ip_address" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.app_server.*.public_ip
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.Konvert_VPC.id
}

