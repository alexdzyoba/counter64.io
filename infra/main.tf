provider "aws" {
  region  = "eu-west-1"
  profile = "counter64"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_route" "internet" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_key_pair" "admin" {
  key_name   = "admin-key"
  public_key = file(var.ssh_pubkey_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic from specific IP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.allow_ssh.id

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ssh_cidr_blocks
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic from anywhere"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_http_ingress" {
  security_group_id = aws_security_group.allow_http.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_any_egress" {
  security_group_id = aws_security_group.allow_http.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_ami" "debian" {
  owners = ["379101102735"] # Debian
  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-2019-11-13-63558"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.debian.id
  instance_type = "t2.nano"

  key_name = aws_key_pair.admin.key_name

  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
  ]
  associate_public_ip_address = true

  tags = {
    Name = "app"
    Role = "app"
  }
}

resource "aws_eip" "public" {
  instance = aws_instance.app.id
  vpc      = true
}

data "aws_route53_zone" "root" {
  name = "counter64.io."
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = "www.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.public.public_ip]
}
