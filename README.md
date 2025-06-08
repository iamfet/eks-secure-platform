# EKS Secure Platform

A production-ready, security-focused Terraform implementation for deploying Amazon EKS clusters with best practices for security, networking, and access control.

## Overview

This repository contains infrastructure as code (IaC) for deploying a secure Amazon EKS (Elastic Kubernetes Service) platform. It implements AWS and Kubernetes security best practices to provide a robust foundation for running containerized applications.

## Security Best Practices Implemented

### Network Security
- **Private Subnet Deployment**: EKS nodes run in private subnets with no direct internet access
- **Network Segmentation**: Clear separation between public and private subnets
- **Single NAT Gateway**: Controlled outbound internet access for private subnets
- **Proper Subnet Tagging**: EKS-specific tags for load balancer integration
- **DNS Support**: Enhanced security with DNS hostnames and support enabled

### Access Control
- **Role-Based Access Control (RBAC)**:
  - Strict Kubernetes RBAC policies for both cluster and namespace levels
  - Namespace isolation for application workloads (online-boutique)
  - Least privilege principle applied to all roles
  
- **AWS IAM Integration**:
  - External IAM roles with limited permissions
  - Clear separation between admin, developer, and deployer roles
  - Fine-grained EKS API access policies

### Authentication
- **API Authentication Mode**: Modern EKS authentication using API mode instead of legacy ConfigMap
- **Access Entries**: Explicit access entries for all users with appropriate permissions
- **AWS IAM Integration**: Leveraging AWS identity for secure cluster access

### Authorization
- **Least Privilege Principle**: Users granted only permissions necessary for their role
- **Scoped Access**: Namespace-scoped access for developers, cluster-wide for admins
- **Policy Associations**: EKS policies (AmazonEKSViewPolicy, AmazonEKSClusterAdminPolicy) applied at appropriate scopes
- **Access Scope Restrictions**: Developers restricted to specific namespaces

### Kubernetes Security
- **Namespace Isolation**: Dedicated namespace for application workloads
- **Limited Role Bindings**: Specific permissions bound to specific users
- **View-Only Access**: Developers limited to view-only access for their namespace
- **Cluster Admin Restriction**: Cluster admin access limited to terraform-deployer only

## Architecture

The infrastructure consists of:

1. **VPC and Networking**:
   - Custom VPC with public and private subnets
   - NAT Gateway for outbound internet access
   - Proper subnet tagging for EKS integration

2. **EKS Cluster**:
   - Managed node groups for simplified operations
   - Private subnet deployment for enhanced security
   - Modern API authentication mode

3. **IAM Roles and Policies**:
   - External admin role with view-only cluster access
   - External developer role with namespace-scoped access
   - Terraform deployer role with admin access for CI/CD

4. **Kubernetes Resources**:
   - Namespace for application isolation
   - RBAC roles and bindings for access control
   - Cluster and namespace-level permissions

## AWS IAM Roles and Access

This infrastructure creates the following IAM roles with specific permissions:

### Role: external-admin
- **Purpose**: For administrative users requiring cluster visibility
- **AWS Permissions**: `eks:DescribeCluster`, `eks:ListClusters`
- **EKS Policy**: AmazonEKSViewPolicy
- **Kubernetes Access**: Cluster-wide view-only access
- **Scope**: Entire cluster

### Role: external-developer
- **Purpose**: For development team members
- **AWS Permissions**: `eks:DescribeCluster`
- **EKS Policy**: AmazonEKSViewPolicy
- **Kubernetes Access**: View-only access
- **Scope**: Limited to `online-boutique` namespace

### Role: terraform-deployer
- **Purpose**: For CI/CD automation and infrastructure management
- **AWS Permissions**: Uses existing user/role
- **EKS Policy**: AmazonEKSClusterAdminPolicy
- **Kubernetes Access**: Full cluster administrator
- **Scope**: Entire cluster

### Access Flow

1. Users assume their respective IAM role (`external-admin` or `external-developer`)
2. Users authenticate to the EKS cluster using these roles
3. EKS API authentication mode maps IAM roles to Kubernetes users
4. Kubernetes RBAC then enforces appropriate permissions

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate permissions
- kubectl for Kubernetes interaction

## Repository Structure

```
eks-secure-platform/
├── backend/                 # Terraform backend configuration
│   ├── main.tf              # S3 bucket and DynamoDB table for state
│   └── outputs.tf           # Backend resource outputs
├── main.tf                  # VPC and EKS cluster configuration
├── iam-roles.tf             # IAM roles for external users
├── kube-resources.tf        # Kubernetes RBAC configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── providers.tf             # Provider configuration
└── terraform.tfvars         # Variable values
```

## Usage

1. **Initialize the backend** (if using remote state):
   ```bash
   cd backend
   terraform init
   terraform apply
   cd ..
   ```

2. **Configure variables**:
   Create a `terraform.tfvars` file with required variables:
   ```hcl
   vpc_cidr_block = "10.0.0.0/16"
   private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
   public_subnets_cidr = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
   project_name = "myapp"
   cluster_version = "1.28"
   aws_region = "us-west-2"
   user_for_admin_role = "arn:aws:iam::ACCOUNT_ID:user/admin-user"
   user_for_dev_role = "arn:aws:iam::ACCOUNT_ID:user/dev-user"
   user_for_terraform_deployer = "arn:aws:iam::ACCOUNT_ID:user/ci-user"
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access the cluster**:
   ```bash
   aws eks update-kubeconfig --name myapp-eks-cluster --region us-west-2
   kubectl get nodes
   ```
   
## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the terms specified in the LICENSE file.