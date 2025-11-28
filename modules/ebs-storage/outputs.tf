output "storage_class_name" {
  value = kubernetes_storage_class.ebs_gp3.metadata[0].name
}
