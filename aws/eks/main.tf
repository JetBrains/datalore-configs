locals {
  name            = "datalore"
  cluster_version = "1.20"
  region          = "us-east-1"
  pool_size       = 3
  instance_types  = ["m5.large"]
}

provider "aws" {
  region = local.region
}

module "eks" {
  source                          = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v18.7.2"
  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    default_node_group = {
      ami_type                   = "AL2_x86_64"
      #ami_type                   = "BOTTLEROCKET_x86_64"
      #platform                   = "bottlerocket"
      disk_size                  = 50
      instance_types             = local.instance_types
      iam_role_attach_cni_policy = true
      create_launch_template     = false
      launch_template_name       = ""
      min_size                   = local.pool_size
      max_size                   = local.pool_size
      desired_size               = local.pool_size
    }
  }
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

module "vpc_cni_irsa" {
  # TODO change source
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-role-for-service-accounts-eks?ref=v4.12.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.12.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }
}
