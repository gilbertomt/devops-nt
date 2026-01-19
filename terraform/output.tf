output "ecr_repository_url" {
  description = "URL do repositório ECR da aplicação"
  value       = aws_ecr_repository.devops_nt_app.repository_url
}

output "aws_region" {
  description = "Região AWS"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "nginx_ingress_hostname" {
  description = "Endereço do LoadBalancer do NGINX Ingress"
  value       = "Aguardar alguns minutos após apply para obter o hostname"
}

output "app_namespace" {
  description = "Namespace da aplicação"
  value       = var.deploy_helm ? kubernetes_namespace_v1.devops_nt_app[0].metadata[0].name : ""
}

output "nginx_namespace" {
  description = "Namespace do NGINX Ingress"
  value       = var.deploy_helm ? kubernetes_namespace_v1.ingress_nginx[0].metadata[0].name : ""
}