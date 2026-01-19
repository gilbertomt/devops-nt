#
# Configuração da Network com módulo oficial do Terraform para VPC na AWS
#
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = format("%s-vpc", var.project_name)
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  tags = merge(
    var.common_tags,
    {
      Name = format("%s-vpc", var.project_name)
      Type = "VPC"
    }
  )

  private_subnet_tags = {
    "Name"                                                            = format("%s-sub-private", var.project_name),
    "kubernetes.io/role/internal-elb"                                 = 1,
    "kubernetes.io/cluster/${format("%s-cluster", var.project_name)}" = "shared"
  }

  public_subnet_tags = {
    "Name"                                                            = format("%s-sub-public", var.project_name),
    "kubernetes.io/role/elb"                                          = 1,
    "kubernetes.io/cluster/${format("%s-cluster", var.project_name)}" = "shared"
  }

}