provider "aws" {
  region = var.aws_region
}


#VPC for Cluster
data "aws_availability_zones" "azs" {
  state = "available"
} #queries AWS to provide the names of availability zones dynamically

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = " ~> 5.21"

  name            = "${var.project_name}-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnets_cidr
  public_subnets  = var.public_subnets_cidr
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared" # Tags required for EKS to discover subnets
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                                = 1 # Identifies this subnet for external load balancers
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/internal_elb"                       = 1 # Identifies this subnet for internal services
  }

}

#EKS for Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = "${var.project_name}-eks-cluster"
  cluster_version = var.cluster_version

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id

  cluster_endpoint_public_access = true

  create_cluster_security_group = false
  create_node_security_group    = false

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns = {}
  }

  # Set authentication mode to API
  authentication_mode = "API"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  
  # Add access entries including your current identity
  access_entries = {
    admin = {
      principal_arn = aws_iam_role.external-admin.arn
      username      = "admin"
      type          = "STANDARD"

      # Grant developer access with view-only permissions
      policy_associations = {
        viewer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    developer = {
      principal_arn = aws_iam_role.external-developer.arn
      username      = "developer"
      type          = "STANDARD"

      # Grant developer access with view-only permissions to specific namespace
      policy_associations = {
        viewer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["online-boutique"]
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t2.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 4
    }
  }
  tags = {
    environment = "development"
    application = "${var.project_name}"
  }

}