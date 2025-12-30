output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region eu-central-1 --name ${module.eks.cluster_name}"
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = module.bastion.bastion_instance_id
}

output "ssm_connect_command" {
  description = "Command to connect to bastion via SSM"
  value       = "aws ssm start-session --target ${module.bastion.bastion_instance_id} --region eu-central-1"
}
