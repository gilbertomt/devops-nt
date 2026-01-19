#!/bin/bash
set -e

#
# Resolve a localização do projeto baseado na localização do script
#
ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#
# Destruir Infraestrutura
#
echo "========================================"
echo " Destruir Infraestrutura DevOps NT"
echo "========================================"
echo ""
echo "## AVISO: Esta operação VAI DELETAR:"
echo "   - Cluster Kubernetes (EKS)"
echo "   - VPC, subnets, e NAT Gateway"
echo "   - Repositório ECR"
echo "   - Todos os volumes e dados"
echo ""
echo "Esta ação NÃO pode ser desfeita!"
echo ""

read -p "Deseja continuar? Digite 'sim' para confirmar: " confirmation

if [ "$confirmation" != "sim" ]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo ">> Confirmação recebida. Iniciando destruição..."
echo ""

cd "$ROOT_DIR/terraform"

echo ">> Destruindo infraestrutura com Terraform..."
echo "   (inclui NGINX, aplicação e todos os recursos)"
terraform destroy -auto-approve

echo ""
echo "========================================"
echo " Destruição concluída com sucesso"
echo "========================================"
echo ""
echo "✓ Cluster EKS foi deletado"
echo "✓ VPC foi deletada"
echo "✓ Repositório ECR foi deletado"
echo "✓ Todos os recursos foram removidos"
echo ""
echo "Dica: Se quiser usar este projeto novamente, execute:"
echo "      bash deploy.sh"
echo ""
