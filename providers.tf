terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37"
    }
  }

}