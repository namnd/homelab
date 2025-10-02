module "vpc" {
  source = "./modules/aws-vpc"

  cidr_block = "10.0.0.0/16"
  name       = "headscale-vpc"

}

locals {
  ami           = "ami-0279a86684f669718" # Canonical, Ubuntu, 24.04, amd64 noble image
  instance_type = "t2.micro"              # Free tier
}

resource "aws_key_pair" "nam" {
  key_name   = "nam"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8HjC+29D66x0zOMMwrleHKHN4bD5hBmIqKzc3FALQo"
}

data "template_file" "headscale_config" {
  template = file("${path.module}/config.yaml")

  vars = {
    hostname = "${local.subdomain}.${local.domain}"
    email    = "me@namnd.com"
  }
}

data "template_file" "user_data" {
  template = format(
    "%s",
    file("${path.module}/user_data.sh"),
  )

  vars = {
    headscale_config_base64 = base64encode(data.template_file.headscale_config.rendered)
  }
}
resource "aws_instance" "this" {
  ami = local.ami

  instance_type               = local.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true

  user_data_base64            = base64encode(data.template_file.user_data.rendered)
  user_data_replace_on_change = true

  key_name = aws_key_pair.nam.key_name

  tags = {
    Name = "${local.namespace}-cp"
  }
}

resource "aws_security_group" "this" {
  name   = "${local.namespace}-sg"
  vpc_id = module.vpc.vpc_id

  revoke_rules_on_delete = true

  tags = {
    Name = "${local.namespace}-sg"
  }

}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "${chomp(data.http.myip.response_body)}/32"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}
