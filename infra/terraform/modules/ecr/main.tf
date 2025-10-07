locals { map_repos = { for r in var.repositories : r => r } }

resource "aws_ecr_repository" "repos" {
  for_each             = local.map_repos
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  lifecycle_policy {
    policy = jsonencode({
      rules = [{
        rulePriority = 1
        description  = "retain last 30 images"
        selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 30 }
        action    = { type = "expire" }
      }]
    })
  }
}
