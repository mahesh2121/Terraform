#!/usr/bin/env bash
# secrets-hunt.sh — scan the repo for leaked-secret SHAPES (CI-gate friendly).
# Usage (from repo root): ./terragrunt-tutorial/16-company-challenges/labs/lab-3-secrets/scripts/secrets-hunt.sh
# Exit 0 = clean, exit 1 = findings (fails CI, as it should).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "🔍 Scanning for leaked secrets in: $ROOT"
echo ""

findings="$(grep -rEn \
  --exclude-dir=.git \
  --exclude-dir=.terragrunt-cache \
  --exclude-dir=.terraform \
  --exclude='secrets-hunt.sh' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  -e 'ghp_[0-9A-Za-z]{36}' \
  -e 'xox[baprs]-[0-9A-Za-z-]+' \
  -e '(password|passwd|secret|api[_-]?key|token)[[:space:]]*=[[:space:]]*"[^"]+"' \
  . || true)"

if [ -z "$findings" ]; then
  echo "✅ No leaked-secret shapes found."
  exit 0
fi

echo "❌ FINDINGS (file:line:matched line):"
echo "$findings"
echo ""
echo "Fix order: 1) ROTATE the credential  2) remove from code (use env/secret manager)"
echo "3) enable GitHub push protection. See labs/lab-3-secrets/README.md."
exit 1
