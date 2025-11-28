resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.27.0-eksbuild.1"

  service_account_role_arn = var.ebs_csi_role_arn
}
