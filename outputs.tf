output "alb_endpoint" {
  value = "http://${aws_lb.app_alb.dns_name}"
}

output "standalone_ec2_public_ip" {
  value = aws_instance.standalone_server.public_ip
}
