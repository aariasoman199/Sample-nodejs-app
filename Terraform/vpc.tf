resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
}

resource "aws_subnet" "public_subnets" {

  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_environment}-public_${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {

  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, "${count.index + 3}")
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_environment}-private_${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_environment}-public"
  }
}

resource "aws_route_table_association" "public_subnets" {

  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {

  count  = var.enable_nat_gw == true ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-${var.project_environment}-nat"
  }
}

resource "aws_nat_gateway" "ngw" {

  count = var.enable_nat_gw == true ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
  depends_on = [aws_internet_gateway.igw]

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.project_environment}-private"
  }
}


resource "aws_route" "nat_gw_route" {
  count                  = var.enable_nat_gw == true ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[0].id
}



resource "aws_route_table_association" "private_subnets" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-bastion"
  description = "${var.project_name}-${var.project_environment}-bastion"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-bastion"
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion.id

}

resource "aws_security_group" "loadbalancer" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-loadbalancer"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  description = "${var.project_name}-${var.project_environment}-loadbalancer"
  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-loadbalancer"
  }
}


resource "aws_security_group_rule" "loadbalancer_ingress_rule" {
  for_each          = toset(var.loadbalancer_ports)
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.loadbalancer.id

}


resource "aws_security_group" "webserver" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-webserver"
  description = "${var.project_name}-${var.project_environment}-webserver"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-webserver"
  }
}

resource "aws_security_group_rule" "webserver_ingress_alb" {

  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.loadbalancer.id
  security_group_id        = aws_security_group.webserver.id

}

resource "aws_security_group_rule" "webserver_ingress_ssh" {

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.webserver.id

}

resource "aws_security_group" "database" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-database"
  description = "${var.project_name}-${var.project_environment}-database"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-database"
  }
}

resource "aws_security_group_rule" "database_ingress_webserver" {

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webserver.id
  security_group_id        = aws_security_group.database.id

}

resource "aws_security_group_rule" "database_ingress_ssh" {

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.database.id

}
