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

# Grant bastion host access to EKS cluster
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.bastion.bastion_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.bastion.bastion_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion]
}
