# This is a sample EKS cluster deployment with Ubuntu worker nodes.
# Adjust accordingly, as required.

locals {
  aws_region = "eu-central-1"
  cluster_version = "1.30"
  cluster_name = "datalore-eks-${random_string.suffix.result}"
  instance_type = "t3.large"
  min_size = 1
  desired_size = 2
  max_size = 3
}

provider "aws" {
  region = local.aws_region
}

data "aws_ami" "eks_ubuntu_ami" {
  most_recent      = true
  owners           = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${local.cluster_version}/images/hvm-ssd/*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

output "ami" {
  value = data.aws_ami.eks_ubuntu_ami.arn
}

# Filter out local zones, which are not currently supported with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "datalore-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "20.13.1"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  enable_irsa = true
}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name = "datalore-ubuntu-nodes"

  cluster_name = local.cluster_name
  cluster_version = local.cluster_version
  cluster_service_cidr = module.eks.cluster_service_cidr
  subnet_ids = module.vpc.private_subnets

  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks.cluster_primary_security_group_id,
    module.eks.cluster_security_group_id,
  ]
  use_custom_launch_template = true
  enable_bootstrap_user_data = true

  min_size     = local.min_size
  desired_size = local.desired_size
  max_size     = local.max_size

  instance_types = [local.instance_type]

  ami_type = "CUSTOM"
  ami_id = "${data.aws_ami.eks_ubuntu_ami.image_id}"

}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"
  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.31.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
  depends_on = [ module.eks_managed_node_group ]
}