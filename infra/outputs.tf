output "public_ip" {
  value = aws_eip.public.public_ip
}

output "public_dns" {
  value = aws_route53_record.www.name
}
