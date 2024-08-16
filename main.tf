data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "kms_key_policy" {
  source_policy_documents = var.policy.policy_documents

  dynamic "statement" {
    for_each = var.policy.enable_default_policy ? [true] : []

    content {
      sid = "Read/list permissions"
      actions = [
        "kms:Describe*",
        "kms:ListAliases",
        "kms:ListKeys",
        "kms:GetKeyPolicy"
      ]
      effect    = "Allow"
      resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.policy.enable_default_policy ? [true] : []

    content {
      sid       = "Base Permissions for root"
      actions   = ["kms:*"]
      effect    = "Allow"
      resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalType"
        values   = ["Account"]
      }

      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.policy.iam_arns_administrative) > 0 ? [true] : []

    content {
      sid = "Administrative permissions"
      actions = [
        "kms:CancelKeyDeletion",
        "kms:Create*",
        "kms:Decrypt",
        "kms:Delete*",
        "kms:Describe*",
        "kms:Disable*",
        "kms:Enable*",
        "kms:Encrypt",
        "kms:Get*",
        "kms:List*",
        "kms:Put*",
        "kms:ReplicateKey",
        "kms:Revoke*",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:Update*"
      ]
      effect    = "Allow"
      resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]

      principals {
        type        = "AWS"
        identifiers = var.policy.iam_arns_administrative
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key.policy.iam_arns_decrypt) > 0 ? [true] : []

    content {
      sid = "Decrypt permissions"
      actions = [
        "kms:Decrypt"
      ]
      effect    = "Allow"
      resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]

      principals {
        type        = "AWS"
        identifiers = var.kms_key.policy.iam_arns_decrypt
      }
    }
  }
}

resource "aws_kms_alias" "default" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.default.key_id
}

resource "aws_kms_key" "default" {
  customer_master_key_spec = var.customer_master_key_spec
  deletion_window_in_days  = var.deletion_window_in_days
  description              = coalesce(var.description, var.name)
  enable_key_rotation      = var.enable_key_rotation
  is_enabled               = true
  key_usage                = var.key_usage
  multi_region             = var.multi_region
  policy                   = length(iam_arns_administrative) > 0 ? coalesce(var.policy.custom_policy, data.aws_iam_policy_document.kms_key_policy.json) : var.policy.custom_policy
  tags                     = var.tags
}
