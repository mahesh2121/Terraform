#!/usr/bin/env bash
# fix-deprecated-region.sh — auto-fix data.aws_region.<label>.name → .region
#
#   ./fix-deprecated-region.sh [DIR]          DRY-RUN (default): show what would change
#   ./fix-deprecated-region.sh --apply [DIR]  actually rewrite the files
#
# Safety rules:
#   • NEVER touches .terraform/ (upgrade those modules instead)
#   • NEVER touches poc-deprecated-attr/before (the intentional repro)
#   • ⚠️ Only correct for stacks on AWS provider >= 6.0 (.region is absent on v5)!
#   • Re-scans after writing and reports any leftovers.
set -uo pipefail

APPLY=0
DIR="."
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h | --help) sed -n '2,12p' "$0"; exit 0 ;;
    *) DIR="$arg" ;;
  esac
done

PATTERN='aws_region\.[A-Za-z0-9_-]+\.name([^A-Za-z0-9_]|$)'
SED_EXPR='s/(aws_region\.[A-Za-z0-9_-]+)\.name([^A-Za-z0-9_]|$)/\1.region\2/g'
REPRO='poc-deprecated-attr/before/'

echo "🔧 Deprecated .name → .region fixer (target: $DIR)"
echo "⚠️  Only valid for AWS provider >= 6.0 stacks — check versions.tf first!"
echo ""

files="$(grep -rEl --include='*.tf' \
  --exclude-dir=.git --exclude-dir=.terraform \
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d \
  -e "$PATTERN" "$DIR" 2>/dev/null | grep -v "$REPRO" || true)"

if [ -z "$files" ]; then
  echo "✅ Nothing to fix (repro + downloaded modules excluded by design)."
  exit 0
fi

file_n="$(printf '%s\n' "$files" | grep -c .)"
occ_n="$(grep -rEoh --include='*.tf' -e "$PATTERN" "$DIR" 2>/dev/null | grep -c . || true)"
echo "Found occurrences in $file_n file(s):"
printf '%s\n' "$files" | while IFS= read -r f; do echo "  • $f"; done
echo ""

if [ "$APPLY" -eq 0 ]; then
  echo "── DRY-RUN (no files written). Matches that would be rewritten: ──"
  grep -rEn --include='*.tf' \
    --exclude-dir=.git --exclude-dir=.terraform \
    --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d \
    -e "$PATTERN" "$DIR" | grep -v "$REPRO" || true
  echo ""
  echo "Re-run with --apply to write the fix."
  exit 0
fi

printf '%s\n' "$files" | while IFS= read -r f; do
  [ -z "$f" ] && continue
  sed -E -i.bak "$SED_EXPR" "$f" && rm -f "$f.bak"
  echo "  ✏️  fixed: $f"
done
echo ""

# Verify: re-scan for leftovers (exits nonzero-safe thanks to || true)
left="$(grep -rEn --include='*.tf' \
  --exclude-dir=.git --exclude-dir=.terraform \
  --exclude-dir=.terragrunt-cache --exclude-dir=.terraform.d \
  -e "$PATTERN" "$DIR" 2>/dev/null | grep -v "$REPRO" || true)"
if [ -z "$left" ]; then
  echo "✅ Done — 0 occurrences left in own code. Now run: terraform validate"
else
  echo "⚠️  Leftovers (re-run the fixer, then inspect manually):"
  echo "$left"
fi

# Remind about upstream hits this script deliberately never touches
moddirs="$(find "$DIR" -type d -name .terraform 2>/dev/null || true)"
if [ -n "$moddirs" ]; then
  # shellcheck disable=SC2086
  upstream="$(grep -rEoh --include='*.tf' -e "$PATTERN" $moddirs 2>/dev/null | grep -c . || true)"
  [ "$upstream" -gt 0 ] && echo "ℹ️  Plus $upstream occurrence(s) inside .terraform/ — upgrade those modules; this script never edits them."
fi
exit 0
