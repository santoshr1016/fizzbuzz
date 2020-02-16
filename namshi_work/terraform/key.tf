resource "aws_key_pair" "mykeypair" {
  key_name   = "mykey"
  public_key = file(var.ssh_key_path)
}

