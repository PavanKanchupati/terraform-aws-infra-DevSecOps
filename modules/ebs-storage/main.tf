resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = var.storage_class_name
    annotations = var.default ? {
      "storageclass.kubernetes.io/is-default-class" = "true"
    } : {}
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type = "gp3"
    fsType = var.fs_type
  }

  reclaim_policy = var.reclaim_policy
  volume_binding_mode = var.volume_binding_mode
  allow_volume_expansion = true
}
