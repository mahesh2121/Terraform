#!/usr/bin/env bash
# fix-deprecated-region.sh — auto-fix safe AWS provider v6 renames:
#   ✅ data.aws_region.<label>.name  → .region
#   ✅ aws_s3_bucket.<label>.region  → .bucket_region
#   🖐️ vpc = true (aws_eip)          → flagged for MANUAL review (never auto-edited:
#                                      sed cannot confirm the resource type)
#
#   ./fix-deprecated-region.sh [DIR]          DRY-RUN (default): show what would change
#   ./fix-deprecated-region.sh --apply [DIR]  actually rewrite the files
#
# Safety rules:
#   • NEVER touches .terraform/ (upgrade those modules instead)
#   • NEVER touches poc-deprecated-attr/before (the intentional repro)
#   • ⚠️ Only correct for stacks on AWS provider >= 6.0!
#   • Re-scans after writing and reports any leftovers.
set -uo pipefail

APPLY=0
DIR="."
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h | --help) sed -n '2,14p' "$0"; exit 0 ;;
    *) DIR="$arg" ;;
  esac
done

P_REGION='aws_region\.[A-Za-z0-9_-]+\.name([^A-Za-z0-9_]|$)'
P_S3='aws_s3_bucket\.[A-Za-z0-9_-]+\.region([^A-Za-z0-9_]|$)'
P_EIP='^[[:space:]]*vpc[[:space:]]*=[[:space:]]*true([^A-Za-z0-9_]|$)'
SED_REGION='s/(aws_region\.[A-Za-z0-9_-]+)\.name([^A-Za-z0-9_]|$)/\1.region\2/g'
SED_S3='s/(aws_s3_bucket\.[A-Za-z0-9_-]+)\.region([^A-Za-z0-9_]|$)/\1.bucket_region\2/g'
REPRO='poc-deprecated-attr/before/'

GREP_FILES=(grep -rEl --include='*.tf'
  --exclude-dir=.git --exclude-dir=.terraform
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d)
GREP_LINES=(grep -rEn --include='*.tf'
  --exclude-dir=.git --exclude-dir=.terraform
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d)

echo "🔧 v6 deprecation fixer (target: $DIR)"
echo "⚠️  Only valid for AWS provider >= 6.0 stacks — check versions.tf first!"
echo ""

# Auto-fixable files (aws_region .name + s3 .region only — eip stays manual)
files="$("${GREP_FILES[@]}" -e "$P_REGION" -e "$P_S3" "$DIR" 2>/dev/null | grep -v "$REPRO" || true)"
eip_hits="$("${GREP_LINES[@]}" -e "$P_EIP" "$DIR" 2>/dev/null | grep -v "$REPRO" || true)"

if [ -z "$files" ]; then
  echo "✅ Nothing auto-fixable (repro + downloaded modules excluded by design)."
else
  file_n="$(printf '%s\n' "$files" | grep -c .)"
  echo "Auto-fixable occurrences in $file_n file(s):"
  printf '%s\n' "$files" | while IFS= read -r f; do echo "  • $f"; done
  echo ""
fi

if [ "$APPLY" -eq 0 ]; then
  if [ -n "$files" ]; then
    echo "── DRY-RUN (no files written). Matches that would be rewritten: ──"
    "${GREP_LINES[@]}" -e "$P_REGION" -e "$P_S3" "$DIR" 2>/dev/null | grep -v "$REPRO" || true
    echo ""
    echo "Re-run with --apply to write the fix."
  fi
else
  if [ -n "$files" ]; then
    printf '%s\n' "$files" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      sed -E -i.bak -e "$SED_REGION" -e "$SED_S3" "$f" && rm -f "$f.bak"
      echo "  ✏️  fixed: $f"
    done
    echo ""
    left="$("${GREP_LINES[@]}" -e "$P_REGION" -e "$P_S3" "$DIR" 2>/dev/null | grep -v "$REPRO" || true)"
    if [ -z "$left" ]; then
      echo "✅ Done — 0 auto-fixable occurrences left. Now run: terraform validate"
    else
      echo "⚠️  Leftovers (re-run the fixer, then inspect manually):"
      echo "$left"
    fi
  fi
fi

if [ -n "$eip_hits" ]; then
  echo ""
  echo "🖐️  MANUAL REVIEW needed (vpc = true → domain = \"vpc\", verify aws_eip first):"
  echo "$eip_hits"
fi

# Remind about upstream hits this script deliberately never touches
moddirs="$(find "$DIR" -type d -name .terraform 2>/dev/null || true)"
if [ -n "$moddirs" ]; then
  # shellcheck disable=SC2086
  upstream="$(grep -rEoh --include='*.tf' -e "$P_REGION" -e "$P_S3" -e "$P_EIP" $moddirs 2>/dev/null | grep -c . || true)"
  [ "$upstream" -gt 0 ] && echo "ℹ️  Plus $upstream occurrence(s) inside .terraform/ — upgrade those modules; this script never edits them."
fi
exit 0
