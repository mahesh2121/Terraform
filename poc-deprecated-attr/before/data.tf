# BEFORE (broken) — the data source both versions share.
# Nothing wrong HERE; the problem is which ATTRIBUTE locals.tf reads.

data "aws_region" "current" {}
