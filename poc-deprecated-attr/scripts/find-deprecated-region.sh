#!/usr/bin/env bash
# find-deprecated-region.sh — count EVERY data.aws_region.<label>.name usage.
# Terraform collapses repeats into "(and N more similar warnings elsewhere)";
# this gives you their real number, split by what YOU can fix vs upstream code.
#
#   ./find-deprecated-region.sh [DIR]          full scan, exit 0 (includes this
#                                              POC's intentional repro: before/)
#   ./find-deprecated-region.sh --check [DIR]  CI mode: excludes the intentional
#                                              repro, exit 1 on any other finding
set -uo pipefail

CHECK=0
DIR="."
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    -h | --help) sed -n '2,10p' "$0"; exit 0 ;;
    *) DIR="$arg" ;;
  esac
done

PATTERN='aws_region\.[A-Za-z0-9_-]+\.name([^A-Za-z0-9_]|$)'
REPRO='poc-deprecated-attr/before/'

if [ "$CHECK" -eq 1 ]; then
  echo "🛡️  CI MODE — intentional repro ($REPRO) excluded"
fi
echo "🔍 Scanning for deprecated data.aws_region.<label>.name in: $DIR"
echo ""

# 1) Your own code (everything except caches, VCS, and downloaded modules)
own="$(grep -rEn --include='*.tf' \
  --exclude-dir=.git --exclude-dir=.terraform \
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d \
  -e "$PATTERN" "$DIR" || true)"
if [ "$CHECK" -eq 1 ]; then
  own="$(printf '%s\n' "$own" | grep -v "$REPRO" || true)"
fi

# 2) Downloaded modules (upgrade the module — never hand-edit these)
moddirs="$(find "$DIR" -type d -name .terraform 2>/dev/null || true)"
mods=""
if [ -n "$moddirs" ]; then
  # shellcheck disable=SC2086
  mods="$(grep -rEn --include='*.tf' -e "$PATTERN" $moddirs || true)"
fi

count() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | grep -c .; }
own_n="$(count "$own")"
mod_n="$(count "$mods")"

echo "── YOUR CODE: $own_n occurrence(s) ──"
[ -n "$own" ] && echo "$own"
echo ""
echo "── DOWNLOADED MODULES (.terraform/): $mod_n occurrence(s) ──"
[ -n "$mods" ] && echo "$mods"
echo ""

if [ "$CHECK" -eq 1 ]; then
  if [ "$own_n" -gt 0 ]; then
    echo "❌ CI GATE FAILED — $own_n deprecated .name usage(s). Fix with:"
    echo "   ./poc-deprecated-attr/scripts/fix-deprecated-region.sh --apply ."
    exit 1
  fi
  echo "✅ CI gate passed — no deprecated .name in own code."
  exit 0
fi

echo "TOTAL: $((own_n + mod_n))  →  fix your $own_n (.name → .region); upgrade modules for the $mod_n."
[ "$((own_n + mod_n))" -eq 0 ] && echo "✅ Clean — no deprecated usages found."
exit 0
