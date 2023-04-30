resource "aws_instance" "test-ec2-instance" {
  ami             = "ami-0e5e62d36ed699ae3"
  instance_type   = "r5d.xlarge"
  key_name        = aws_key_pair.key_pair.id
  security_groups = [aws_security_group.ingress_all_test.id]
  #   associate_public_ip_address = true

  user_data = <<-EOF
      #! /bin/bash
      ln -s /dev/sde /users/bob
      sudo groupadd bobbers
      sudo useradd bob -m -d /users/bob 
      sudo usermod -a -G bobbers bob
      sudo chown bob:bobbers /users/bob -R
    EOF

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "amazonlinux"
  }
  subnet_id = aws_subnet.subnet-uno.id
}

resource "aws_ebs_volume" "test-ec2-instance_volume_50" {
  availability_zone = aws_instance.test-ec2-instance.availability_zone

  size = 50
  tags = {
    Name = "test-ec2-instance_volume_50"
  }
}
resource "aws_volume_attachment" "test-ec2-instance_volume_50_attach" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.test-ec2-instance_volume_50.id
  instance_id = aws_instance.test-ec2-instance.id
}

output "public_ip" {
  value = aws_instance.test-ec2-instance.public_ip
}
