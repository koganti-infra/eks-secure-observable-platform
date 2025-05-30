provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Project" = "eks-platform"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = "eks-secure-observable"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      subnet_ids     = module.vpc.private_subnets
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 4
      min_size       = 1
    }
  }

  tags = {
    Environment = "dev"
    Project     = "eks-platform"
  }
}
