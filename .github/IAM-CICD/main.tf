# RUN ONCE
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Variables
variable "github_org" {
  default = "Qday12"
}

variable "github_repo" {
  default = "Cloud-cluster-provisioning-EKS"
}

variable "project_name" {
  default = "cloud-cluster-provisioning-eks"
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Plan Role (Read-Only)
resource "aws_iam_role" "plan" {
  name = "${var.project_name}-github-plan-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "plan" {
  name = "${var.project_name}-plan-policy"
  role = aws_iam_role.plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "cloudfront:Get*",
          "cloudfront:List*",
          "cloudfront:Describe*",
          "wafv2:Get*",
          "wafv2:List*",
          "wafv2:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "cloudwatch:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:Describe*",
          "iam:Get*",
          "iam:List*",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      }
    ]
  })
}

# Apply Role (Full Write)
resource "aws_iam_role" "apply" {
  name = "${var.project_name}-github-apply-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply" {
  name = "${var.project_name}-apply-policy"
  role = aws_iam_role.apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3FullAccess"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      },
      {
        Sid      = "CloudFrontFullAccess"
        Effect   = "Allow"
        Action   = "cloudfront:*"
        Resource = "*"
      },
      {
        Sid      = "WAFFullAccess"
        Effect   = "Allow"
        Action   = "wafv2:*"
        Resource = "*"
      },
      {
        Sid    = "CloudWatchFullAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMLimited"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:ListRoles"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "plan_role_arn" {
  description = "Add to GitHub Secrets as AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Add to GitHub Secrets as AWS_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}
