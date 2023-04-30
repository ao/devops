resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "test3-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh

  # provisioner "local-exec" {    # Generate "terraform-key-pair.pem" in current directory
  #   command = <<-EOT
  #     echo '${tls_private_key.key_pair.private_key_pem}' > ./thiskey.pem
  #     chmod 400 ./thiskey.pem
  #   EOT
  # }
}
# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}
