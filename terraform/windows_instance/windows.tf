resource "aws_instance" "windows_ec2" {
    ami                    = "ami-0cce8617a46e028ec"  # Replace with the appropriate Windows AMI ID
    instance_type          = "t3.medium"
    key_name               = aws_key_pair.key_pair.key_name
    vpc_security_group_ids = [aws_security_group.example_security_group.id]
    subnet_id              = aws_subnet.example_subnet.id

  user_data = <<EOF
<powershell>
  Rename-Computer -NewName CTPIWPMSMA01 -Force -Restart
</powershell>
EOF

  root_block_device {
    volume_size = 150
    volume_type = "gp2"
    tags = {
      Name = "windows_ec2_root_volume"
    }
  }

  tags = {
    Name        = "Windows EC2 Instance"
    Environment = "Production"
  }
}

resource "aws_volume_attachment" "volume_attachment_d" {
  device_name = "D:"
  volume_id   = aws_ebs_volume.ebs_volume_d.id
  instance_id = aws_instance.windows_ec2.id
}

resource "aws_volume_attachment" "volume_attachment_e" {
  device_name = "E:"
  volume_id   = aws_ebs_volume.ebs_volume_e.id
  instance_id = aws_instance.windows_ec2.id
}

resource "aws_ebs_volume" "ebs_volume_d" {
  availability_zone = aws_instance.windows_ec2.availability_zone
  size              = 200
  type              = "gp2"
  encrypted         = true
  tags = {
    Name = "windows_ec2_volume_d"
  }
}

resource "aws_ebs_volume" "ebs_volume_e" {
  availability_zone = aws_instance.windows_ec2.availability_zone
  size              = 200
  type              = "gp2"
  encrypted         = true
  tags = {
    Name = "windows_ec2_volume_e"
  }
}
