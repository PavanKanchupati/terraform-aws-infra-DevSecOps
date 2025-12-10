############################################
# 1. AWS Provider
############################################
provider "aws" {
  region = "ap-south-1"
}

############################################
# 2. VPC Module
############################################
module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["ap-south-1a", "ap-south-1b"]
}

############################################
# 3. Security Groups
############################################
module "security_groups" {
  source = "../../modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

############################################
# 4. IAM (Cluster role + Node role)
############################################
module "iam" {
  source = "../../modules/iam"

  cluster_role_name = "dev-eks-cluster-role"
  node_role_name    = "dev-eks-node-role"
}

############################################
# 5. EKS Cluster
############################################
module "eks" {
  source = "../../modules/eks"

  cluster_name     = "aws-jenkins-infra-cluster-dev"
  subnet_ids       = module.vpc.subnet_ids
  cluster_role_arn = module.iam.cluster_role_arn
}

############################################
# 6. IAM-IRSA (OIDC + EBS CSI driver role)
############################################
module "iam_irsa" {
  source = "../../modules/iam-irsa"

  cluster_name = module.eks.cluster_name
  cluster_oidc_issuer = module.eks.cluster_oidc_issuer
}

############################################
# 7. EKS Addons (AWS-managed EBS CSI driver)
############################################
module "eks_addons" {
  source = "../../modules/eks-addons"

  cluster_name       = module.eks.cluster_name
  ebs_csi_role_arn   = module.iam_irsa.ebs_csi_role_arn
}

############################################
# 8. NodeGroup
############################################
module "nodegroup" {
  source = "../../modules/nodegroup"

  cluster_name  = module.eks.cluster_name
  node_role_arn = module.iam.node_role_arn
  subnet_ids    = module.vpc.subnet_ids
  ssh_key_name  = var.ssh_key_name

  desired_size = 2
  min_size     = 1
  max_size     = 3
}

############################################
# 9. Kubernetes Provider
############################################


#provider "kubernetes" {
 # host                   = data.aws_eks_cluster.eks.endpoint
  #token                  = data.aws_eks_cluster_auth.eks.token
  #cluster_ca_certificate = base64decode(
  # data.aws_eks_cluster.eks.certificate_authority[0].data
  #)
#}

############################################
# 10. EBS StorageClass (gp3) – default
############################################
#module "ebs_storage" {
 # source = "../../modules/ebs-storage"
#
 # storage_class_name = "gp3-sc"
  #fs_type            = "ext4"
  #default            = true
#}

