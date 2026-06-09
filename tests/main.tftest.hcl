# Mock aws provider, otherwise Terraform tries to connect to the service API.
# aws_caller_identity feeds aws_iam_session_context.arn, which the provider
# ARN-validates, so it needs a syntactically valid mocked ARN.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:role/terraform"
      id         = "123456789012"
      user_id    = "AROAEXAMPLEID"
    }
  }
}

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

  # aws_iam_policy_document is rendered by the AWS provider, so under mock_provider
  # its `json` attribute is a generated value rather than the real policy. We can't
  # assert on individual statements here; overriding it with a known value lets us
  # assert the policy-selection logic (default_policy.enable + var.policy) instead.
  override_data {
    target = data.aws_iam_policy_document.kms_key_policy
    values = {
      json = "{\"Sid\":\"GeneratedDefault\"}"
    }
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

  # KMS key policy: with no explicit policy and default_policy.enable defaulting to
  # true, the generated default policy is applied to the key.
  assert {
    condition     = aws_kms_key.default.policy == "{\"Sid\":\"GeneratedDefault\"}"
    error_message = "Expected the generated default policy to be applied, got: ${aws_kms_key.default.policy}"
  }
}

# An explicit policy must take precedence over the generated default policy.
run "explicit_policy_takes_precedence" {
  command = plan

  module {
    source = "./"
  }

  override_data {
    target = data.aws_iam_policy_document.kms_key_policy
    values = {
      json = "{\"Sid\":\"GeneratedDefault\"}"
    }
  }

  variables {
    name   = "explicit-${run.setup.random_string}"
    policy = "{\"Sid\":\"Explicit\"}"
  }

  assert {
    condition     = aws_kms_key.default.policy == "{\"Sid\":\"Explicit\"}"
    error_message = "Expected the explicit policy to take precedence over the generated default, got: ${aws_kms_key.default.policy}"
  }
}

# When default_policy.enable is false and no explicit policy is set, the key policy
# is left unmanaged so AWS applies its built-in default key policy. The module
# output reflects this as null.
run "default_policy_disabled_is_unmanaged" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name = "disabled-${run.setup.random_string}"
    default_policy = {
      enable = false
    }
  }

  assert {
    condition     = output.policy == null
    error_message = "Expected output.policy to be null when default_policy.enable is false and no policy is set"
  }
}

# When default_policy.enable is false but an explicit policy is supplied, that
# policy is used verbatim and the generated default is not consulted.
run "default_policy_disabled_with_explicit_policy" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name   = "disabled-explicit-${run.setup.random_string}"
    policy = "{\"Sid\":\"Explicit\"}"
    default_policy = {
      enable = false
    }
  }

  assert {
    condition     = output.policy == "{\"Sid\":\"Explicit\"}"
    error_message = "Expected the explicit policy to be used when default_policy.enable is false, got: ${output.policy}"
  }
}
