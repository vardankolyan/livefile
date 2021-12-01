resource "aws_subnet" "terra-subnet-public-1" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region_subnet}"
  tags = {
    Name = "terra_subnet_public_1"
  }
}
