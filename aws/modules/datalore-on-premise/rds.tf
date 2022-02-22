resource "random_string" "db_password" {
  length           = 20
  special          = true
  override_special = "_-"

  count = var.create_database == true ? 1 : 0
}

resource "aws_db_instance" "datalore" {
  identifier                  = "${var.name_prefix}-postgres"
  allocated_storage           = var.db_storage_size
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "12.5"
  instance_class              = var.db_instance_class
  username                    = "postgres"
  password                    = random_string.db_password[0].result
  allow_major_version_upgrade = false
  apply_immediately           = true
  auto_minor_version_upgrade  = false
  skip_final_snapshot         = true
  storage_encrypted           = true
  backup_retention_period     = 7
  availability_zone           = var.datalore_az != null ? var.datalore_az : data.aws_availability_zones.available.names[0]
  db_subnet_group_name        = aws_db_subnet_group.db[0].id
  publicly_accessible         = false
  vpc_security_group_ids      = [aws_security_group.db[0].id]

  count = var.create_database == true ? 1 : 0
}
