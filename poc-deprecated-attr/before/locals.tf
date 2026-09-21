# BEFORE (broken) — line 6 triggers the exact warning from the issue:
#   Warning: Deprecated attribute
#   The attribute "name" is deprecated.

locals {
  region     = data.aws_region.current.name
  account_id = "111111111111" # placeholder — warning fires without any AWS call
}
