variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "admin_role_arns" {
  description = "List of IAM role ARNs to grant EKS cluster admin access"
  type        = list(string)
  default     = []
}
