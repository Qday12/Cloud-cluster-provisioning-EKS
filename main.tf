module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  node_instance_type = var.node_instance_type
  desired_capacity   = var.desired_capacity
}

module "bastion" {
  source = "./modules/bastion"

  cluster_name          = var.cluster_name
  vpc_id                = module.eks.vpc_id
  vpc_cidr              = module.eks.vpc_cidr
  private_subnet_ids    = module.eks.private_subnet_ids
  bastion_instance_type = var.bastion_instance_type
}
