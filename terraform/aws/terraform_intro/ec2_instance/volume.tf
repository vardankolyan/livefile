resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.vol2.id
  instance_id = aws_instance.terra_instance.id
}

resource "aws_ebs_volume" "vol2" {
  availability_zone = "${var.aws_region_subnet}"
  size              = 1
}
