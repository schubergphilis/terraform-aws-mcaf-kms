# Mock aws provider, otherwise Terraform tries to connect to the service API.
mock_provider "aws" {}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

# The default test checks logic in module when using it's default values when creating a plan.
# Additional tests below check individual variables and changes to their defaults. Try not to
# create assertions for resource fields that reference just the variable.
run "default" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name = "default-${run.setup.random_string}"
  }

  # KMS key alias
  assert {
    condition     = aws_kms_alias.default.name == "alias/default-${run.setup.random_string}"
    error_message = "Expected KMS alias name to be alias/default-${run.setup.random_string}, got: ${aws_kms_alias.default.name}"
  }

  # KMS key
  assert {
    condition     = aws_kms_key.default.deletion_window_in_days == 30
    error_message = "Expected KMS key deletion window to be 30 days, got: ${aws_kms_key.default.deletion_window_in_days}"
  }

  assert {
    condition     = aws_kms_key.default.description == "default-${run.setup.random_string}"
    error_message = "Expected KMS key description to be default-${run.setup.random_string}, got: ${aws_kms_key.default.description}"
  }

  assert {
    condition     = aws_kms_key.default.enable_key_rotation == true
    error_message = "Expected KMS key rotation to be enabled, got: ${aws_kms_key.default.enable_key_rotation}"
  }

  assert {
    condition     = aws_kms_key.default.is_enabled == true
    error_message = "Expected KMS key to be enabled, got: ${aws_kms_key.default.is_enabled}"
  }
}
