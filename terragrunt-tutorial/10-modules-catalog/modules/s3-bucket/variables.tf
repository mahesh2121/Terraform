# CATALOG MODULE contract — every environment-specific value is a variable.

variable "bucket_name" {
  description = "Base name for the bucket (a random suffix is appended for global uniqueness)"
  type        = string
}

variable "versioning_enabled" {
  description = "Whether S3 versioning is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
