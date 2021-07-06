resource "aws_ecr_repository" "computation-agent" {
  name = "${var.name_prefix}/computation-agent"
}
resource "aws_ecr_repository" "computation-agent-gpu" {
  name = "${var.name_prefix}/computation-agent-gpu"
}
