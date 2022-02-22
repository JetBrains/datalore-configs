variable "name_prefix" {}
variable "ssh_keypair" {}

variable "datalore_az" {
  default = null
}

variable "create_database" {
  default = true
  type = bool
}
variable "use_elastic_ip" {
  default = false
  type    = bool
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
variable "db_storage_size" {
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
variable "ssh_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "use_nat_gateway" {
  default = false
  type    = bool
}

variable "nat_gateway_routes" {
  default = []
  type    = list(string)
}
variable "default_agents_route" {
  default = true
  type    = bool
}