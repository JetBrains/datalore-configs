module "datalore-on-premise" {
  source      = "../modules/datalore-on-premise"
  datalore_az = var.datalore_az
  ssh_keypair = var.ssh_keypair
  aws_region  = var.aws_region
}
