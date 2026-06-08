locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = var.region != null ? var.region : data.aws_region.current.region

  # if no administrators are specified, include the current user to prevent key from getting unmanaged
  iam_administrator = coalescelist(var.default_policy.iam_arns_administrator, [data.aws_iam_session_context.current.issuer_arn])
}

data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" { arn = data.aws_caller_identity.current.arn }
data "aws_partition" "current" {}
data "aws_region" "current" {}

################################################################################
# Key
################################################################################

resource "aws_kms_alias" "default" {
  region        = var.region
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.default.key_id
}

resource "aws_kms_key" "default" {
  region                   = var.region
  custom_key_store_id      = var.custom_key_store_id
  customer_master_key_spec = var.customer_master_key_spec
  deletion_window_in_days  = var.deletion_window_in_days
  description              = coalesce(var.description, var.name)
  enable_key_rotation      = var.enable_key_rotation
  is_enabled               = true
  key_usage                = var.key_usage
  multi_region             = var.multi_region
  policy                   = var.default_policy.enable ? coalesce(var.policy, data.aws_iam_policy_document.kms_key_policy.json) : var.policy
  xks_key_id               = var.xks_key_id
  tags                     = var.tags
}

################################################################################
# Policy
################################################################################

data "aws_iam_policy_document" "kms_key_policy" {
  override_policy_documents = var.default_policy.override_policy_documents
  source_policy_documents   = var.default_policy.source_policy_documents

  # Allow root account full access to prevent key from getting unmanaged.
  statement {
    sid       = "AllowRootAccount"
    actions   = ["kms:*"]
    effect    = "Allow"
    resources = ["arn:${local.partition}:kms:${local.region}:${local.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalType"
      values   = ["Account"]
    }

    principals {
      type = "AWS"
      identifiers = [
        "arn:${local.partition}:iam::${local.account_id}:root"
      ]
    }
  }

  # Allow all principals in the account read-only access. This is required to allow users to view the key in the AWS console.
  dynamic "statement" {
    for_each = var.default_policy.iam_all_principals_read ? [true] : []

    content {
      sid = "AllowAllPrincipalsRead"
      actions = [
        "kms:Describe*",
        "kms:GetKeyPolicy",
      ]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      }
    }
  }

  # Allow principals specified in iam_arns_administrator to have permissions to manage the KMS key, 
  # but no permissions to use the KMS key in cryptographic operations. 
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators
  dynamic "statement" {
    for_each = length(local.iam_administrator) > 0 ? [true] : []

    content {
      sid = "AllowAdministrator"
      actions = [
        "kms:CancelKeyDeletion",
        "kms:Create*",
        "kms:Delete*",
        "kms:Describe*",
        "kms:Disable*",
        "kms:Enable*",
        "kms:Get*",
        "kms:ImportKeyMaterial",
        "kms:List*",
        "kms:Put*",
        "kms:ReplicateKey",
        "kms:Revoke*",
        "kms:RotateKeyOnDemand",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:Update*"
      ]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.default_policy.iam_arns_administrator
      }
    }
  }

  # Allow principals specified in iam_arns_decrypt to have permissions to use the KMS key for decryption operations, but not encryption operations.
  dynamic "statement" {
    for_each = length(var.default_policy.iam_arns_decrypt) > 0 ? [true] : []

    content {
      sid = "AllowDecrypt"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.default_policy.iam_arns_decrypt
      }
    }
  }

  # Allow principals specified in iam_arns_decrypt_encrypt to have permissions to use the KMS key in cryptographic operations.
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users
  dynamic "statement" {
    for_each = length(var.default_policy.iam_arns_decrypt_encrypt) > 0 ? [true] : []

    content {
      sid = "AllowDecryptEncrypt"
      actions = concat(
        [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
        ],
        var.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? ["kms:GenerateDataKey*"] : ["kms:GetPublicKey"]
      )
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.default_policy.iam_arns_decrypt_encrypt
      }
    }
  }

  # Allow principals specified in iam_arns_owner to have full access to the key. 
  dynamic "statement" {
    for_each = length(var.default_policy.iam_arns_owner) > 0 ? [true] : []

    content {
      sid       = "AllowOwner"
      actions   = ["kms:*"]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.default_policy.iam_arns_owner
      }
    }
  }

  # Allow principals specified in iam_arns_sign_verify to have permissions to use the KMS key for signing and verification operations.
  dynamic "statement" {
    for_each = length(var.default_policy.iam_arns_sign_verify) > 0 ? [true] : []

    content {
      sid = "AllowSignVerify"
      actions = [
        "kms:DescribeKey",
        "kms:GetPublicKey",
        "kms:Sign",
        "kms:Verify",
      ]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.default_policy.iam_arns_sign_verify
      }
    }
  }

  # Allow AWS Config service read access to the key. This is required for AWS Config to be able to record configuration changes to the key and related events.
  dynamic "statement" {
    for_each = var.default_policy.iam_aws_config_read ? [true] : []

    content {
      sid = "AllowAwsConfigRead"
      actions = [
        "kms:Describe*",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus"
      ]
      effect    = "Allow"
      resources = ["*"]

      principals {
        type = "AWS"
        identifiers = [
          "arn:${local.partition}:iam::${local.account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
        ]
      }
    }
  }
}
