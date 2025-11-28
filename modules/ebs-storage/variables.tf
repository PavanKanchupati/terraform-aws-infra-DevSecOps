variable "storage_class_name" {
  type        = string
  default     = "gp3-sc"
  description = "Name of the storage class"
}

variable "fs_type" {
  type        = string
  default     = "ext4"
  description = "Filesystem type for EBS volumes"
}

variable "reclaim_policy" {
  type        = string
  default     = "Delete"
  description = "Delete or Retain PVs"
}

variable "volume_binding_mode" {
  type        = string
  default     = "WaitForFirstConsumer"
  description = "Binding mode for PVCs"
}

variable "default" {
  type        = bool
  default     = false
  description = "Set this storage class as default"
}
