resource "aws_ecr_repository" "evaluator" {
  name = "${var.name_prefix}/computation-evaluator"
}
resource "aws_ecr_repository" "evaluator-gpu" {
  name = "${var.name_prefix}/computation-evaluator-gpu"
}
resource "aws_ecr_repository" "computation-agent" {
  name = "${var.name_prefix}/computation-agent"
}
