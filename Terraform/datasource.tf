data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_acm_certificate" "elb_certificate" {
  domain      = var.domain_name
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
