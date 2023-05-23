provider "aws" {
  region = "af-south-1"
}

resource "aws_vpc" "cluster_vpc" {
  cidr_block = cidrsubnet("172.21.0.0/16", 0, 0)
  tags = {
    Name = "cluster_vpc"
  }
}

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "tmp-1-2-3-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}
output "private_key_file" {
  value       = tls_private_key.key_pair.private_key_pem
  description = "Private key file path"
  sensitive   = true
}

# Write private key to a file
resource "null_resource" "write_private_key" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.key_pair.private_key_pem}' > private_key.pem"
  }
}

# Create a security group allowing RDP access
resource "aws_security_group" "example_security_group" {
  name        = "example-security-group"
  description = "Allow RDP access"
  vpc_id      = aws_vpc.cluster_vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a subnet
resource "aws_subnet" "example_subnet" {
  vpc_id            = aws_vpc.cluster_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.cluster_vpc.cidr_block, 1, 0)
  availability_zone = "af-south-1a"
}

# Create a Windows EC2 instance
resource "aws_instance" "example_instance" {
  ami                    = "ami-0cce8617a46e028ec"  # Replace with the appropriate Windows AMI ID
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.example_security_group.id]
  subnet_id              = aws_subnet.example_subnet.id

  tags = {
    Name = "example-instance"
  }
}
