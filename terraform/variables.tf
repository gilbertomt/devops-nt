#
# Variáveis globais do Projeto
#
variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "devops-nt-app"
}

variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "development"
}

variable "common_tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default = {
    Project     = "devops-nt-app"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}

#
# Variáveis da Rede
#
variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnets" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

#
# Variáveis do EKS
#
variable "kubernetes_version" {
  description = "Versão do EKS"
  type        = string
  default     = "1.33"
}

variable "desired_size" {
  description = "Tamanho desejado do grupo de nós do EKS"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Tamanho mínimo do grupo de nós do EKS"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Tamanho máximo do grupo de nós do EKS"
  type        = number
  default     = 5
}

variable "instance_types" {
  description = "Tipos de instância para os nós do EKS"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Tamanho do disco para os nós do EKS"
  type        = number
  default     = 20
}

variable "ami_type" {
  description = "Tipo de AMI para os nós do EKS"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

#
# Variáveis da Aplicação
#
variable "app_replicas" {
  description = "Número de replicas da aplicação"
  type        = number
  default     = 3
}

variable "app_image_repository" {
  description = "Repositório da imagem da aplicação (será preenchido pelo script)"
  type        = string
  default     = ""
}

variable "app_image_tag" {
  description = "Tag da imagem da aplicação"
  type        = string
  default     = "v1"
}

variable "deploy_helm" {
  description = "Se true, cria releases Helm (cluster deve estar pronto com kubeconfig)"
  type        = bool
  default     = false
}