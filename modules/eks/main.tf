resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
}

}


