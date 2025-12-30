# test
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  node_instance_type = var.node_instance_type
  desired_capacity   = var.desired_capacity
}
