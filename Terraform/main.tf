resource "aws_instance" "bastion_instance" {

  subnet_id              = aws_subnet.public_subnets[0].id
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ssh_auth_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-bastion"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
  lifecycle {
    create_before_destroy = true
  }

}



resource "aws_instance" "db_server" {

  subnet_id              = aws_subnet.private_subnets[1].id
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ssh_auth_key.key_name
  vpc_security_group_ids = [aws_security_group.database.id]
  user_data              = file("dbsetup.sh")
  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-database"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
  lifecycle {
    create_before_destroy = true
  }

}




resource "aws_instance" "nodejsapp" {
  count                  = 2
  ami                    = var.ami_id
  subnet_id              = aws_subnet.private_subnets[count.index].id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name               = aws_key_pair.ssh_auth_key.key_name
  user_data              = file("userdata.sh")

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-webserver"
  }
}


resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-${var.project_environment}-frontend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {

    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "8080"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}


resource "aws_lb_target_group_attachment" "frontend" {
  count            = 2
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.nodejsapp[count.index].id
  port             = 8080
}


resource "aws_lb" "frontend" {
  name               = "${var.project_name}-${var.project_environment}-frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = true

  tags = {
    Environment = "${var.project_name}-${var.project_environment}-frontend"
  }
}

resource "aws_lb_listener" "front_end_https_listner" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.elb_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "frontend_http_listner" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_route53_record" "frontend" {

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "${var.hostname}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}




resource "aws_route53_record" "db_record" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "dbinstance.chottu.shop"
  type    = "A"
  ttl     = 300
  records = [aws_instance.db_server.private_ip]
}


resource "aws_key_pair" "ssh_auth_key" {

  key_name   = "${var.project_name}-${var.project_environment}"
  public_key = file("${var.project_name}-${var.project_environment}.pub")
  tags = {

    "Name"        = "${var.project_name}-${var.project_environment}"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}

