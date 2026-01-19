#!/bin/bash
set -e

#
# Resolve a localização do projeto baseado na localização do script
#
ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#
# Deploy DevOps NT - Ambiente de Teste
#
echo "========================================"
echo " Deploy DevOps NT - Ambiente de Teste"
echo "========================================"

# 
# Variáveis 
#
APP_NAME="devops-nt-app"
IMAGE_TAG="v1"

#
# 1. Terraform - Infraestrutura
#

echo ">> Aplicando infraestrutura com Terraform..."
cd "$ROOT_DIR/terraform"
terraform init
terraform apply -auto-approve \
  -var "app_image_repository=" \
  -var "app_image_tag=$IMAGE_TAG" \
  -var "deploy_helm=false"

echo ">> Lendo outputs do Terraform..."
ECR_REPO=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

cd "$ROOT_DIR"

ECR_REGISTRY=$(echo "$ECR_REPO" | cut -d'/' -f1)

echo ">> ECR Repository : $ECR_REPO"
echo ">> AWS Region    : $AWS_REGION"
echo ">> Cluster Name  : $CLUSTER_NAME"

#
# 2. Build e Push da Imagem
#

echo ">> Login no ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo ">> Build da imagem Docker..."
docker build -f "$ROOT_DIR/app/Dockerfile" -t "$ECR_REPO:$IMAGE_TAG" "$ROOT_DIR"

echo ">> Push da imagem para o ECR..."
docker push "$ECR_REPO:$IMAGE_TAG"

#
# 3. Kubernetes - Configurar Acesso Local
#

echo ">> Atualizando kubeconfig..."
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

#
# 4. Terraform - Deploy da Aplicação (Helm)
#

echo ">> Re-aplicando Terraform com imagem ECR..."
cd "$ROOT_DIR/terraform"
terraform apply -auto-approve \
  -var "app_image_repository=$ECR_REPO" \
  -var "app_image_tag=$IMAGE_TAG" \
  -var "deploy_helm=true"

cd "$ROOT_DIR"

#
# 5. Finalização (aguarda LoadBalancer e resume)
#

echo ">> Aguardando LoadBalancer do NGINX..."
TIMEOUT=300  # 5 minutos
ELAPSED=0
INTERVAL=20

while [ $ELAPSED -lt $TIMEOUT ]; do
  NGINX_LB=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  
  if [ -n "$NGINX_LB" ] && [ "$NGINX_LB" != "null" ]; then
    break
  fi
  
  echo "   [$ELAPSED/$TIMEOUT] LoadBalancer ainda não provisionado. Aguardando..."
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ -z "$NGINX_LB" ] || [ "$NGINX_LB" = "null" ]; then
  echo ""
  echo "## AVISO: LoadBalancer ainda não foi provisionado após $TIMEOUT segundos."
  echo ""
  echo "Possíveis causas:"
  echo "  1. Verificar status do NGINX Ingress:"
  echo "     kubectl get pods -n ingress-nginx"
  echo "     kubectl describe svc ingress-nginx-controller -n ingress-nginx"
  echo "  2. Verificar logs do NGINX:"
  echo "     kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx"
  echo "  3. Verificar eventos do cluster:"
  echo "     kubectl get events -n ingress-nginx"
  echo ""
  echo "Você pode tentar novamente com:"
  echo "  kubectl get svc ingress-nginx-controller -n ingress-nginx"
  echo ""
  NGINX_LB="[PENDENTE - Verifique os comandos acima]"
else

echo "========================================"
echo " Deploy finalizado"
echo "----------------------------------------"
echo "Aplicação: devops-nt-app"
echo "Namespace: devops-nt-app"
echo "LoadBalancer NGINX:"
echo "http://$NGINX_LB"
echo "========================================"
fi


