#
# Namespace NGINX Ingress
#
resource "kubernetes_namespace_v1" "ingress_nginx" {
  count = var.deploy_helm ? 1 : 0
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [module.eks]
}

#
# NGINX Ingress Controller via Helm
#
resource "helm_release" "nginx_ingress" {
  count      = var.deploy_helm ? 1 : 0
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx[0].metadata[0].name
  version    = "4.11.3"

  set = [
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
      value = "true"
    }
  ]
  depends_on = [
    module.eks,
    kubernetes_namespace_v1.ingress_nginx
  ]
}

#
# Namespace da aplicação
#
resource "kubernetes_namespace_v1" "devops_nt_app" {
  count = var.deploy_helm ? 1 : 0
  metadata {
    name = "devops-nt-app"
  }

  depends_on = [module.eks]
}

#
# Helm Release da aplicação
#
resource "helm_release" "devops_nt_app" {
  count            = var.deploy_helm ? 1 : 0
  name             = "devops-nt-app"
  chart            = "${path.root}/../helm/devops-nt-app"
  namespace        = kubernetes_namespace_v1.devops_nt_app[0].metadata[0].name
  upgrade_install  = true

  timeout = 600
  wait    = false

  # Valores da aplicação
  set = [
    {
      name  = "image.repository"
      value = var.app_image_repository != "" ? var.app_image_repository : aws_ecr_repository.devops_nt_app.repository_url
    },
    {
      name  = "image.tag"
      value = var.app_image_tag
    },
    {
      name  = "replicaCount"
      value = var.app_replicas
    }
  ]
  depends_on = [
    kubernetes_namespace_v1.devops_nt_app,
    helm_release.nginx_ingress
  ]
}
