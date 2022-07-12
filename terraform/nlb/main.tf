resource "aws_lb" "test" {
  name               = "test-nlb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets = [for subnet in data.aws_subnet_ids.default.ids: subnet]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-nlb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}
