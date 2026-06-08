output "arn" {
  value       = aws_kms_key.default.arn
  description = "ARN of the key"
}

output "id" {
  value       = aws_kms_key.default.key_id
  description = "ID of the key"
}

output "policy" {
  value       = var.default_policy.enable ? coalesce(var.policy, data.aws_iam_policy_document.kms_key_policy.json) : var.policy
  description = "Output for entire policy document"
}
