# Upgrading Notes

This document captures required refactoring on your part when upgrading to a module version that contains breaking changes.

## Upgrading to v2.0.0

### Key Changes

- The module now generates a **least-privilege key policy by default**. When `default_policy.enable` is `true` (the new default) and no explicit `policy` is provided, the module builds the key policy from the new `default_policy` object instead of letting AWS apply its built-in default key policy.
- **This changes how access to the key is granted.** AWS's default key policy delegates full control to IAM via an unconditional `arn:aws:iam::<account>:root` principal, meaning any IAM principal with the right IAM permissions can use the key. The generated policy instead constrains the root-account statement with `aws:PrincipalType = "Account"` (break-glass for the account root user only) and grants encryption/decryption, signing and administration **explicitly** through the `default_policy.iam_arns_*` fields. After upgrading, IAM-policy-based access that previously worked implicitly will stop working unless the principals are listed explicitly. Read-only metadata access remains delegated to IAM for all account principals while `iam_all_principals_read` is `true`.
- If `default_policy.iam_arns_administrator` is empty, the calling identity (`aws_iam_session_context.issuer_arn`) is added as administrator so the key is never left without a manageable principal.

### Required actions

**This release is backwards compatible if you already pass `var.policy`**: it still takes precedence over the generated policy, so the resulting key policy is unchanged.
Note: the module now always reads the `aws_caller_identity`, `aws_partition` and `aws_iam_session_context` data sources,
so the principal running Terraform needs `sts:GetCallerIdentity` and (for assumed-role sessions) `iam:GetRole`/`iam:GetUser`.
If you relied on AWS's default key policy (no `policy` set) and want to **keep that behaviour**, set `default_policy = { enable = false }`.

To **adopt the new model**, set `var.policy` to `null` and grant access using `var.default_policy`, for example:

```hcl
default_policy = {
  iam_arns_administrator   = ["arn:aws:iam::123456789012:role/key-admins"]
  iam_arns_decrypt_encrypt = ["arn:aws:iam::123456789012:role/app"]
}
```

## Upgrading to v1.0.0

### Key Changes

- This module now requires a minimum AWS provider version of 6.0 to support the `region` parameter. If you are using multiple AWS provider blocks, please read [migrating from multiple provider configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/enhanced-region-support#migrating-from-multiple-provider-configurations).
