output id {
  value       = aws_kms_key.default.key_id
  description = "ID of the key"
}

output arn {
  value       = aws_kms_key.default.arn
  description = "ARN of the key"
}
