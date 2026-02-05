#
# Configuração do EKS com módulo oficial do Terraform para EKS na AWS
#
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.14.0"

  name                                     = format("%s-cluster", var.project_name)
  kubernetes_version                       = var.kubernetes_version
  subnet_ids                               = module.vpc.private_subnets
  vpc_id                                   = module.vpc.vpc_id
  endpoint_private_access                  = true
  enable_cluster_creator_admin_permissions = true
  
  # O acesso público ao endpoint do cluster fica habilitado para facilitar o acesso via kubectl e Helm.
  # Apenas para caráter de laboratório, deste modo não faz necessário configurar VPN ou bastion host para acessar o cluster.
  endpoint_public_access                   = true
  # Em desemvolvimento e produção, é recomendado restringir o acesso público por questões de segurança.
  
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = format("%s-cluster", var.project_name)
      Type = "EKS-Cluster"
    }
  )

  eks_managed_node_groups = {
    eks_nodes = {
      name                 = format("%s-nodes", var.project_name)
      launch_template_name = format("%s-lt", var.project_name)
      ami_type             = var.ami_type
      instance_types       = var.instance_types

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
      disk_size    = var.disk_size

      tags = merge(
        var.common_tags,
        {
          Name = format("%s-node", var.project_name)
          Type = "EKS-Node"
        }
      )
    }
  }

}

