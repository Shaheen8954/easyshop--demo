locals {

  region          = "eu-west-1"
  environment     = "dev"
  tags = {
    Name          = "easyshop"
    Environment   = "dev"
    Terraform     = "true"
  }

  # VPC Variables
  vpc_name        = "easyshop"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  intra_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]

  # EKS Variables
  cluster_name    = "easyshop-cluster"
  cluster_version = "1.29"
  eks_addon_versions = {
    coredns = "v1.11.1-eksbuild.4"
    kube-proxy = "v1.29.2-eksbuild.1"
    vpc-cni = "v1.16.0-eksbuild.1"
    aws-ebs-csi-driver = "v1.29.0-eksbuild.1"
  }

  # Security Group Variables
  sg_name = "easyshop-sg"

  # Bastion Variables
  key_name      = "bastion_key.pem"
  instance_type = "t3.large"
}