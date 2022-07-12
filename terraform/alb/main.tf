resource "aws_lb" "test" {
  name               = "test-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets = [for subnet in data.aws_subnet_ids.default.ids: subnet]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test" {
  name        = "tf-example-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls_alb"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_lb_target_group_attachment" "alb-attach" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_lb.test.id
}