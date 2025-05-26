output "web_public_ip" {
  description = "The public IP address of web server"
  value = aws_eip.ec2_web_eip[0].public_ip
  depends_on = [ aws_eip.ec2_web_eip ]
}
output "web_public_dns" {
  description = "The public DNS address of web server"
  value = aws_eip.ec2_web_eip[0].public_dns
  depends_on = [aws_eip.ec2_web_eip]
}
output "aws_iam_policy" {
  description = "aws_iam_policy_arn"
  value = aws_iam_policy.ec2_access_policy.arn  
}
output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}

output "vpc_ecr_endpoint" {
  description = "VPC ECR Endpoint"
  value       = aws_vpc_endpoint.ecr_endpoint.dns_entry[0].dns_name
}

output "vpc_ecr_dkr_endpoint" {
  description = "VPC ECR DKR Endpoint"
  value       = aws_vpc_endpoint.ecr_dkr_endpoint.dns_entry[0].dns_name
}