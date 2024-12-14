resource "aws_acm_certificate" "couro_acm" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "couro-certificates"
  }
}

resource "aws_route53_record" "acm_route53" {
  zone_id = var.zone_id
  name    = aws_acm_certificate.couro_acm.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.couro_acm.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.couro_acm.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "ssl_validation" {
  certificate_arn         = aws_acm_certificate.couro_acm.arn
  validation_record_fqdns = [aws_route53_record.acm_route53.fqdn]
}