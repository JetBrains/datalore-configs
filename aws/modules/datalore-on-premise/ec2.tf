data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "datalore" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.datalore_instance_type
  subnet_id                   = aws_subnet.datalore.id
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/user_data.sh",
  { ecr = "${aws_ecr_repository.computation-agent.registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com" })
  iam_instance_profile = aws_iam_instance_profile.datalore.name

  vpc_security_group_ids = [aws_security_group.datalore.id]

  key_name = var.ssh_keypair

  tags = {
    Name = var.name_prefix
  }

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [ami, user_data, volume_tags, ebs_optimized]
  }
}
