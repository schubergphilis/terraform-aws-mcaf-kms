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
  policy                   = var.policy
  xks_key_id               = var.xks_key_id
  tags                     = var.tags
}
