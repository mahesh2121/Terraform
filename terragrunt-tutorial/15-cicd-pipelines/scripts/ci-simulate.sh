#!/usr/bin/env bash
# ci-simulate.sh — run the CI gates LOCALLY (no GitHub, no AWS needed).
# Mirrors workflows/plan.yml steps against the FREE local Lesson-11 example:
#   1. hclfmt check   2. terraform fmt check   3. validate   4. run-all plan
# Usage: ./scripts/ci-simulate.sh   (from lesson 15 folder)
set -euo pipefail

cd "$(dirname "$0")/../.." # → terragrunt-tutorial/
TARGET="11-run-all/live/dev"

have() { command -v "$1" >/dev/null 2>&1; }

echo "════════ CI simulation (target: $TARGET) ════════"

if ! have terragrunt || ! have terraform; then
  echo "⚠️  terragrunt/terraform not installed — showing what CI WOULD run:"
  echo ""
  echo "  cd $TARGET"
  echo "  terragrunt hclfmt --check"
  echo "  terraform fmt -check -recursive ."
  echo "  terragrunt run-all validate --terragrunt-non-interactive"
  echo "  terragrunt run-all plan --terragrunt-non-interactive"
  echo ""
  echo "Install both tools (Lesson 01) and re-run for the real gates."
  exit 0
fi

echo " versions: $(terraform version -json | head -c 60)... / $(terragrunt --version)"
echo ""

echo "── ① hclfmt check ──"
(cd "$TARGET" && terragrunt hclfmt --check) && echo "✅ hclfmt clean"
echo ""

echo "── ② terraform fmt check ──"
terraform fmt -check -recursive "$TARGET" && echo "✅ fmt clean"
echo ""

echo "── ③ run-all validate ──"
(cd "$TARGET" && terragrunt run-all validate --terragrunt-non-interactive) && echo "✅ validate passed"
echo ""

echo "── ④ run-all plan (this diff becomes the PR comment) ──"
(cd "$TARGET" && terragrunt run-all plan --terragrunt-non-interactive)
echo ""
echo "════════ ✅ ALL CI GATES PASSED — safe to push ════════"
