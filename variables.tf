variable "deletion_window_in_days" {
  type        = number
  default     = 30
  description = "Delay in days after which the key is deleted"
}

variable "description" {
  type        = string
  description = "The description of the key as viewed in AWS console"
}

variable "enable_key_rotation" {
  type        = bool
  default     = false
  description = "Specifies whether key rotation is enabled"
}

variable "name" {
  type        = string
  description = "The name of the key"
}

variable "policy" {
  type        = string
  default     = ""
  description = "A valid KMS policy JSON document"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the key"
}
