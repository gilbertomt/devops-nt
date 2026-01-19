#
# Configuração do ECR Repository para a aplicação
#
resource "aws_ecr_repository" "devops_nt_app" {
  name                 = format("%s-ecr", var.project_name)
  image_tag_mutability = "MUTABLE"
  force_delete         = true 

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = format("%s-ecr", var.project_name)
    }
  )
}

resource "aws_ecr_lifecycle_policy" "devops_nt_app" {
  repository = aws_ecr_repository.devops_nt_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter apenas as últimas 10 imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
