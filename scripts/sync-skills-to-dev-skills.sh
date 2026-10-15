#!/usr/bin/env bash
# Copy a fixed set of skills from agent-skills into the dev-skills catalog.
#
# Every skill in the list is self-contained: all of its relative links resolve
# inside its own directory, with no `../` reaching outside the skill. The script
# copies the directories verbatim and then proves that property.
#
# Usage:
#   scripts/sync-skills-to-dev-skills.sh
#   SRC=/path/to/agent-skills DEST=/path/to/dev-skills scripts/sync-skills-to-dev-skills.sh
#
# Safe to re-run: each skill directory is replaced from source on every run.

set -euo pipefail

SRC="${SRC:-/Users/levy/PycharmProjects/agent-skills}"
DEST="${DEST:-/Users/levy/PycharmProjects/dev-skills}"

SKILLS=(
  code-review-and-quality
  security-and-hardening
  performance-optimization
)

log() { echo "$*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

[ -d "$SRC/skills" ] || die "source skills dir not found: $SRC/skills"
[ -d "$DEST" ] || die "destination not found: $DEST"

for skill in "${SKILLS[@]}"; do
  src_dir="$SRC/skills/$skill"
  [ -f "$src_dir/SKILL.md" ] || die "missing SKILL.md: $src_dir"

  log "== $skill"
  rsync -a --delete "$src_dir/" "$DEST/$skill/"
  log "  -> $DEST/$skill"
done

# Assert the copied skills stayed self-contained, then resolve every link.
log ""
log "== link check"
fail=0
for skill in "${SKILLS[@]}"; do
  dest_dir="$DEST/$skill"

  if hits=$(grep -rnE '\.\./[A-Za-z0-9._/-]*\.md' "$dest_dir" --include='*.md' 2>/dev/null); then
    log "  OUTSIDE $skill:"
    echo "$hits" >&2
    fail=1
  fi

  while IFS= read -r link; do
    [ -f "$dest_dir/$link" ] || { log "  BROKEN $skill -> $link"; fail=1; }
  done < <(
    find "$dest_dir" -name '*.md' -type f -exec grep -ohE '\]\(references/[^)#]+\.md' {} + |
      sed 's/^](//' | sort -u
  )
done
[ "$fail" -eq 0 ] || die "link check failed (see above)"

log "  self-contained, all references resolve"
log ""
log "Done. Synced ${#SKILLS[@]} skills into $DEST"
