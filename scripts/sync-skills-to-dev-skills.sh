#!/usr/bin/env bash
# 把三个自包含 skill 从 agent-skills 同步到 dev-skills
set -euo pipefail

SRC="${SRC:-/Users/levy/PycharmProjects/agent-skills}/skills"
DEST="${DEST:-/Users/levy/PycharmProjects/dev-skills}"

for skill in code-review-and-quality security-and-hardening performance-optimization; do
  rsync -a --delete "$SRC/$skill/" "$DEST/$skill/"
done
