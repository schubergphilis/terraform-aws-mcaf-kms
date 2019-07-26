resource aws_kms_alias default {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.default.key_id
}

resource aws_kms_key default {
  description             = var.description
  policy                  = var.policy
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = true
  enable_key_rotation     = var.enable_key_rotation
  tags                    = var.tags
}
