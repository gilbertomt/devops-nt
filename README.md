# DevOps NT - Deploy Automatizado de Aplicação ASP.NET Core

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Complete](https://img.shields.io/badge/Status-Complete-brightgreen.svg)](#)
[![App: ASP.NET Core](https://img.shields.io/badge/App-ASP.NET%20Core-512BD4.svg)](https://dotnet.microsoft.com/apps/aspnet)
[![Language: Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4.svg)](https://www.terraform.io/)
[![Platform: AWS](https://img.shields.io/badge/Platform-AWS-FF9900.svg)](https://aws.amazon.com/)
[![Container: Kubernetes](https://img.shields.io/badge/Container-Kubernetes-326CE5.svg)](https://kubernetes.io/)
[![Package: Helm](https://img.shields.io/badge/Package-Helm-0F1689.svg)](https://helm.sh/)

Aplicação ASP.NET Core rodando em cluster Kubernetes (EKS) na AWS, com infraestrutura provisionada via Terraform e deploy automatizado via Helm.

**Repositório**: https://github.com/gilbertomt/devops-nt

---

## Entregáveis do Projeto

- **Código Terraform** - Provisiona infraestrutura completa na AWS
- **Dockerfile** - Containeriza a aplicação .NET com multi-stage build
- **Manifests Helm** - Gerencia deployment no Kubernetes
- **Documentação** - Instruções completas de execução
- **Scripts de Automação** - Deploy e destroy com um comando

---

## Requisitos

Antes de começar, você precisa ter estas ferramentas instaladas:

1. **Git** - [Instruções de instalação](https://git-scm.com/downloads)
2. **AWS CLI** - [Instruções de instalação](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **Terraform** - [Instruções de instalação](https://developer.hashicorp.com/terraform/install)
4. **kubectl** - [Instruções de instalação](https://kubernetes.io/docs/tasks/tools/)
5. **Helm** - [Instruções de instalação](https://helm.sh/docs/intro/install/)
6. **Docker** - [Instruções de instalação](https://docs.docker.com/get-docker/)

Depois de instalar, configure suas credenciais AWS:

```bash
aws configure
```

Informar:
- `AWS Access Key ID`: credencial de acesso
- `AWS Secret Access Key`: chave secreta
- `Default region name`: `us-east-1`
- `Default output format`: pressionar Enter

Para validar:
```bash
aws sts get-caller-identity
```

---

## Execução Automatizada (Recomendado)

Com os requisitos configurados, clone o projeto e execute:

```bash
git clone https://github.com/gilbertomt/devops-nt
cd devops-nt
bash scripts/deploy.sh
```

O script executa automaticamente as seguintes fases:
1) Primeiro cria a infraestrutura (EKS, VPC, ECR) sem Helm
2) Faz build e push da imagem, depois aplica os charts Helm (ingress + app)

Tempo estimado: 15-20 minutos.

---

## Execução Manual

Para entender cada etapa ou em caso de falha do script automatizado:

### Passo 1: Provisionar infraestrutura

```bash
cd terraform

# Inicializar e validar
terraform init
terraform plan -var="deploy_helm=false"

# Aplicar mudanças (SEM Helm nesta fase)
terraform apply -var="deploy_helm=false"
# Confirmar com 'yes'

# Exportar outputs necessários
export ECR_REPO=$(terraform output -raw ecr_repository_url)
export AWS_REGION=$(terraform output -raw aws_region)
export CLUSTER_NAME=$(terraform output -raw cluster_name)

cd ..
```

Aguardar 10-15 minutos para criação do cluster EKS e recursos relacionados.

**Nota importante**: Use `-var="deploy_helm=false"` para que o Terraform crie apenas a infraestrutura (VPC, EKS, ECR) sem instalar os charts Helm. Você aplicará o Helm no Passo 5.

### Passo 2: Build e push da imagem Docker

```bash
# Autenticar no ECR
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin \
  $(echo "$ECR_REPO" | cut -d'/' -f1)

# Construir imagem
docker build -f app/Dockerfile -t "$ECR_REPO:v1" .

# Enviar para repositório
docker push "$ECR_REPO:v1"
```

### Passo 3: Configurar kubectl

```bash
# Atualizar kubeconfig
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

# Validar conectividade
kubectl get nodes
```

Resultado esperado: 3 nodes com status `Ready`.

### Passo 4: Instalar NGINX Ingress Controller

```bash
# Adicionar repositório Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar controller
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

Aguardar provisionamento do LoadBalancer (2-3 minutos).

### Passo 5: Deploy da aplicação

```bash
# Criar namespace
kubectl create namespace devops-nt-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy via Helm
helm upgrade --install devops-nt-app ./helm/devops-nt-app \
  --set image.repository="$ECR_REPO" \
  --set image.tag="v1" \
  -n devops-nt-app
```

Monitorar status dos pods:
```bash
kubectl get pods -n devops-nt-app -w
```

### Passo 6: Obter URL de acesso

```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
```

Acessar o endereço retornado via navegador ou curl.

---

## Validação do Deployment

### Testar endpoint principal
```bash
curl http://[ENDERECO_DO_LOADBALANCER]/
```

Resposta esperada: mensagem de status da aplicação.

### Verificar nodes do cluster
```bash
kubectl get nodes
```

Resultado: 3 nodes com status `Ready`.

### Verificar pods
```bash
kubectl get pods -n devops-nt-app
```

Resultado: 3 pods com status `Running`.

### Testar health check
```bash
curl http://[ENDERECO_DO_LOADBALANCER]/health
```

Resposta esperada: `{"status":"healthy","service":"devops-nt-app"}`.

---

## Destruir Infraestrutura

### Método Automatizado (Recomendado)

Para remover todos os recursos provisionados:

```bash
bash scripts/destroy.sh
```

Confirmar com `sim` quando solicitado.

### Método Manual

Se você executou o deploy manual, siga estes passos na ordem inversa:

**Passo 1: Remover aplicação**
```bash
helm uninstall devops-nt-app -n devops-nt-app
kubectl delete namespace devops-nt-app
```

**Passo 2: Remover NGINX Ingress Controller**
```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

**Passo 3: Destruir infraestrutura**
```bash
cd terraform
terraform destroy
# Confirmar com 'yes'
cd ..
```

Aguardar 10-15 minutos para remoção completa dos recursos.

---

### Recursos removidos

O destroy (manual ou automatizado) remove:
- Deployment Helm
- NGINX Ingress Controller
- Cluster EKS e nodes
- VPC e recursos de rede
- Repositório ECR (com imagens, se houver)

---

## Troubleshooting

### Comando não encontrado
Ferramenta não instalada. Consultar links na seção Requisitos acima.

### Falha na aplicação
```bash
# Verificar logs
kubectl logs -n devops-nt-app -l app=devops-nt-app

# Ver eventos
kubectl get events -n devops-nt-app --sort-by='.lastTimestamp'
```

### Credenciais AWS inválidas
```bash
aws configure  # Reconfigurar
aws sts get-caller-identity  # Validar
```

### LoadBalancer em estado "pending"
Isso é normal. Aguarde até 5 minutos. Para verificar o status:
```bash
kubectl get svc -n ingress-nginx -w
```

---

## Estrutura do Repositório

```
devops-nt/
│
├── app/                          ← REQUISITO: Aplicação ASP.NET Core
│   ├── Dockerfile               # Multi-stage build
│   └── devops-nt-app/           # Código-fonte C#
│
├── helm/                         ← REQUISITO: Charts Kubernetes
│   └── devops-nt-app/
│       ├── Chart.yaml           # Metadados do chart
│       ├── values.yaml          # Valores configuráveis
│       └── templates/
│           ├── deployment.yaml  # Pod deployment
│           ├── service.yaml     # ClusterIP service
│           └── ingress.yaml     # NGINX ingress
│
├── terraform/                    ← REQUISITO: Infraestrutura como Código
│   ├── providers.tf             # Configuração de providers
│   ├── network.tf               # VPC, subnets, NAT Gateway
│   ├── eks.tf                   # Cluster EKS e node groups
│   ├── ecr.tf                   # ECR com force_delete
│   ├── helm.tf                  # Helm releases (condicionado a deploy_helm)
│   ├── variables.tf             # Variáveis (deploy_helm, app_replicas)
│   └── output.tf                # Outputs (ECR, cluster, region)
│
├── scripts/                      ← Automação
│   ├── deploy.sh                # Deploy em 2 fases
│   └── destroy.sh               # Cleanup automático
│
└── README.md                     ← REQUISITO: Instruções
```

---
