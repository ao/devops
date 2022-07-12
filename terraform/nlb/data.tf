data "aws_vpc" "default" {
  filter {
    name   = "tag:type"
    values = ["main"]
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}