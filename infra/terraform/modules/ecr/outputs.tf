output "repository_urls" { value = { for k, v in aws_ecr_repository.repos : k => v.repository_url } }
