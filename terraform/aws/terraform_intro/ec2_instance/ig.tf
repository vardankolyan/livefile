
resource "aws_internet_gateway" "terra-igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = "terra-igw"
  }
}
