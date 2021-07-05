output "vpc_id" {
  value = aws_vpc.on-premise.id
}
output "datalore_instance" {
  value = aws_instance.datalore
}
output "agents_cidr" {
  value = var.agents_cidr
}
output "datalore_ip" {
  value = aws_instance.datalore.public_ip
}
output "db_endpoint" {
  value = aws_db_instance.datalore.endpoint
}
output "db_password" {
  value = aws_db_instance.datalore.password
}
output "datalore_user" {
  value = "${aws_iam_access_key.datalore.id} ${aws_iam_access_key.datalore.secret}"
}
output "agents_subnet_id" {
  value = aws_subnet.agents.id
}
output "agents_security_group_id" {
  value = aws_security_group.agents.id
}
output "nat_ip" {
  value = var.use_nat_gateway ? aws_eip.nat[0].public_ip : null
}
output "registry_url" {
  value = "${aws_ecr_repository.computation-agent.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.name_prefix}"
}
output "init_script" {
  value = "./datalore.sh --public-ip-address ${aws_instance.datalore.public_ip} --internal-ip-address ${aws_instance.datalore.private_ip} --db-host ${aws_db_instance.datalore.address} --db-password ${aws_db_instance.datalore.password} --aws-access-key ${aws_iam_access_key.datalore.id} --aws-access-secret ${aws_iam_access_key.datalore.secret} --keypair-name ${var.ssh_keypair} --s3-environments-address ${aws_s3_bucket.envs.id} --docker-registry-address ${aws_ecr_repository.computation-agent.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.name_prefix} --agent-iam-profile ${aws_iam_instance_profile.agent.name} --agent-subnet-id ${aws_subnet.agents.id} --security-group-id ${aws_security_group.agents.id} --availability-zone-id ${var.datalore_az} --aws-region ${var.aws_region} init"
}
