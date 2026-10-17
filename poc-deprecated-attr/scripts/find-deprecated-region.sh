#!/usr/bin/env bash
# find-deprecated-region.sh — count deprecated AWS provider v6 patterns:
#   1. data.aws_region.<label>.name   → .region          (auto-fixable)
#   2. aws_s3_bucket.<label>.region   → .bucket_region   (auto-fixable)
#   3. vpc = true  (usually aws_eip)  → domain = "vpc"   (MANUAL review)
#
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
    -h | --help) sed -n '2,12p' "$0"; exit 0 ;;
    *) DIR="$arg" ;;
  esac
done

P_REGION='aws_region\.[A-Za-z0-9_-]+\.name([^A-Za-z0-9_]|$)'
P_S3='aws_s3_bucket\.[A-Za-z0-9_-]+\.region([^A-Za-z0-9_]|$)'
P_EIP='^[[:space:]]*vpc[[:space:]]*=[[:space:]]*true([^A-Za-z0-9_]|$)'
REPRO='poc-deprecated-attr/before/'

GREP_OWN=(grep -rEn --include='*.tf'
  --exclude-dir=.git --exclude-dir=.terraform
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d)

# scan_own <pattern> → matches in your code (repro filtered in --check mode)
scan_own() {
  local out
  out="$("${GREP_OWN[@]}" -e "$1" "$DIR" || true)"
  if [ "$CHECK" -eq 1 ]; then
    out="$(printf '%s\n' "$out" | grep -v "$REPRO" || true)"
  fi
  printf '%s' "$out"
}
count() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | grep -c .; }
show() { [ -n "$1" ] && echo "$1"; :; }

if [ "$CHECK" -eq 1 ]; then
  echo "🛡️  CI MODE — intentional repro ($REPRO) excluded"
fi
echo "🔍 Scanning for deprecated AWS provider v6 patterns in: $DIR"
echo ""

region_hits="$(scan_own "$P_REGION")"; region_n="$(count "$region_hits")"
s3_hits="$(scan_own "$P_S3")";         s3_n="$(count "$s3_hits")"
eip_hits="$(scan_own "$P_EIP")";       eip_n="$(count "$eip_hits")"

echo "── YOUR CODE: aws_region .name → .region  ($region_n) ──"
show "$region_hits"
echo ""
echo "── YOUR CODE: s3 bucket .region → .bucket_region  ($s3_n) ──"
show "$s3_hits"
echo ""
echo "── YOUR CODE: vpc = true → domain = \"vpc\"  ($eip_n, MANUAL review) ──"
show "$eip_hits"
[ "$eip_n" -gt 0 ] && echo "   🖐️  Verify each hit is inside an aws_eip resource, then rewrite by hand."
echo ""

# Downloaded modules: any of the three patterns (upgrade the module instead)
moddirs="$(find "$DIR" -type d -name .terraform 2>/dev/null || true)"
mods=""
if [ -n "$moddirs" ]; then
  # shellcheck disable=SC2086
  mods="$(grep -rEn --include='*.tf' -e "$P_REGION" -e "$P_S3" -e "$P_EIP" $moddirs || true)"
fi
mod_n="$(count "$mods")"
echo "── DOWNLOADED MODULES (.terraform/): $mod_n occurrence(s) ──"
show "$mods"
echo ""

own_n=$((region_n + s3_n + eip_n))
if [ "$CHECK" -eq 1 ]; then
  if [ "$own_n" -gt 0 ]; then
    echo "❌ CI GATE FAILED — $own_n deprecated usage(s) in own code."
    [ $((region_n + s3_n)) -gt 0 ] && echo "   Auto-fixable: ./poc-deprecated-attr/scripts/fix-deprecated-region.sh --apply ."
    [ "$eip_n" -gt 0 ] && echo "   Manual: rewrite vpc = true → domain = \"vpc\" in the file(s) above."
    exit 1
  fi
  echo "✅ CI gate passed — no deprecated v6 patterns in own code."
  exit 0
fi

echo "TOTAL (own code): $own_n  ($((region_n + s3_n)) auto-fixable, $eip_n manual)  |  upstream (.terraform/): $mod_n"
[ "$own_n" -eq 0 ] && [ "$mod_n" -eq 0 ] && echo "✅ Clean — no deprecated usages found."
exit 0
