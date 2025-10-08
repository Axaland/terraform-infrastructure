data "aws_iam_policy_document" "oidc_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "ci_inline" {
  statement {
    sid = "DescribeReadOnly"
    actions = [
      "ec2:Describe*",
      "rds:Describe*",
      "ecs:Describe*",
      "elasticloadbalancing:Describe*",
      "application-autoscaling:Describe*",
      "cloudwatch:DescribeAlarms",
      "tag:GetResources"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRPushPull"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECSDeploy"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:PutScalingPolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassRoleLimited"
    actions   = ["iam:PassRole"]
    resources = var.allowed_passrole_arns
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid = "SecretsReadLimited"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.allowed_secrets_arns
  }
}

resource "aws_iam_role" "github_actions_ci" {
  name               = "${var.env}-github-ci-role"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume.json
}

resource "aws_iam_role_policy" "ci_inline" {
  name   = "${var.env}-ci-inline"
  role   = aws_iam_role.github_actions_ci.id
  policy = data.aws_iam_policy_document.ci_inline.json
}

output "ci_role_arn" {
  value = aws_iam_role.github_actions_ci.arn
}
