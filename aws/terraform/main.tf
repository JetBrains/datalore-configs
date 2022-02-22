module "datalore-on-premise" {
  source      = "../modules/datalore-on-premise"
  name_prefix = "datalore-example-com"
  ssh_keypair = var.ssh_keypair
}
