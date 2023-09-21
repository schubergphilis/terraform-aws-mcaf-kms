resource "aws_kms_alias" "default" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.default.key_id
}

resource "aws_kms_key" "default" {
  deletion_window_in_days = var.deletion_window_in_days
  description             = coalesce(var.description, var.name)
  enable_key_rotation     = var.enable_key_rotation
  is_enabled              = true
  policy                  = var.policy
  tags                    = var.tags
}
