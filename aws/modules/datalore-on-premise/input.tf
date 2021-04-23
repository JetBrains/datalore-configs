variable "aws_region" {}
variable "datalore_az" {}
variable "ssh_keypair" {}

variable "additional_sg_list" {
  default = []
}

variable "use_elastic_ip" {
  default = false
}
variable "name_prefix" {
  default = "datalore-on-premise"
}
variable "datalore_instance_type" {
  default = "t3a.medium"
}
variable "db_instance_class" {
  default = "db.t3.xlarge"
}
variable "disk_size" {
  default = 30
}
variable "db_size" {
  default = 30
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "datalore_cidr" {
  default = "10.0.0.0/24"
}
variable "db_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "agents_cidr" {
  default = "10.0.16.0/20"
}
variable "external_cidr_blocks" {
  default = ["0.0.0.0/0"]
}