resource "aws_instance" "terra_instance" {
  ami           = "ami-0629230e074c580f2"
  instance_type = "t2.micro"


  subnet_id              = aws_subnet.terra-subnet-public-1.id
  vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
  key_name               = "Ubuntu_key"

  tags = {
    Name = "terraform_intro"
  }
}

