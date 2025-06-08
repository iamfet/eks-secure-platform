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

  # Set authentication mode to API
  authentication_mode = "API"

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
    terraform_deployer = {
      principal_arn = var.user_for_terraform_deployer
      username      = "terraform-deployer"
      type          = "STANDARD"

      # Grant admin access to terraform-deployer
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    environment = "development"
    application = "${var.project_name}"
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t2.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 3
    }
  }
}