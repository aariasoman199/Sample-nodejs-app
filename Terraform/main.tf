resource "aws_instance" "db_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = ["sg-04b5021ce9fb8c533"]
  user_data              = file("dbsetup.sh")

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-dbserver"
  }
}


resource "aws_instance" "nodejsapp" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = ["sg-04b5021ce9fb8c533"]
  user_data              = file("userdata.sh")

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-webserver"
  }
}

resource "aws_route53_record" "db_record" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "dbinstance.chottu.shop"
  type    = "A"
  ttl     = 300
  records = [aws_instance.db_server.public_ip]
}
