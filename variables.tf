variable "deletion_window_in_days" {
  type        = number
  default     = 30
  description = "Delay in days after which the key is deleted"
}

variable "description" {
  type        = string
  default     = null
  description = "The description of the key as viewed in AWS console"
}

variable "customer_master_key_spec" {
  type        = string
  default     = "SYMMETRIC_DEFAULT"
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports."

  validation {
    condition     = var.customer_master_key_spec != null ? contains(["SYMMETRIC_DEFAULT", "RSA_2048", "RSA_3072", "RSA_4096", "HMAC_256", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"], var.customer_master_key_spec) : true
    error_message = "Allowed values for customer_master_key_spec are \"SYMMETRIC_DEFAULT\", \"RSA_2048\", \"RSA_3072\", \"RSA_4096\", \"HMAC_256\", \"ECC_NIST_P256\", \"ECC_NIST_P384\", \"ECC_NIST_P521\", \"ECC_SECG_P256K1\"."
  }
}

variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Specifies whether key rotation is enabled"
}

variable "key_usage" {
  type        = string
  default     = "ENCRYPT_DECRYPT"
  description = "Specifies the intended use of the key."

  validation {
    condition     = var.key_usage != null ? contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC"], var.key_usage) : true
    error_message = "Allowed values for key_usage are \"ENCRYPT_DECRYPT\", \"SIGN_VERIFY\", \"GENERATE_VERIFY_MAC\"."
  }
}

variable "multi_region" {
  type        = bool
  default     = false
  description = "Indicates whether the KMS key is a multi-Region (`true`) or regional (`false`) key."
}

variable "name" {
  type        = string
  description = "The name of the key"
}



variable "policy" {
  type = object({
    enable_default_policy   = optional(string, true)
    iam_arns_administrative = optional(list(string), [])
    iam_arns_decrypt        = optional(list(string), [])
    policy_documents        = optional(list(string), [])
    custom_policy           = optional(list(string), null)
  })
  default     = {}
  description = "Configuration object for defining the KMS key policy and permissions"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the key"
}
