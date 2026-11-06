#!/usr/bin/env bash
# story: e06s03
# sync-project-version.sh — keep `game/project.godot`'s `config/version` equal to the
# latest release tag.
#
# Why: `.big-release.yml` claimed CI synced this, and nothing did. The game shipped
# v0.7.0 while advertising 0.1.0 (BUG-016). The export job now syncs before building
# the IPA, and preflight L5c asserts it, so the drift cannot come back silently.
#
#   bash scripts/sync-project-version.sh            # write the latest tag's version
#   bash scripts/sync-project-version.sh 0.8.0      # write an explicit version
#   bash scripts/sync-project-version.sh --check    # exit 1 when out of sync
set -uo pipefail
cd "$(dirname "$0")/.."

PROJECT="game/project.godot"
MODE="${1:---write}"

latest="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
if [ -z "$latest" ]; then
  echo "sync-project-version: no tags found, nothing to sync" >&2
  exit 1
fi
current="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' "$PROJECT" | head -1)"

if [ "$MODE" = "--check" ]; then
  if [ "$current" = "$latest" ]; then
    echo "  version in sync: $current"
    exit 0
  fi
  echo "  project.godot says $current, latest tag is $latest — run: bash scripts/sync-project-version.sh" >&2
  exit 1
fi

target="$latest"
[ "$MODE" != "--write" ] && target="$MODE"

if [ "$current" = "$target" ]; then
  echo "  version already $target"
  exit 0
fi
# BSD and GNU sed disagree on -i; write through a temp file instead.
tmp="$(mktemp)"
sed "s|^config/version=\".*\"\$|config/version=\"$target\"|" "$PROJECT" >"$tmp" && mv "$tmp" "$PROJECT"
echo "  version $current -> $target in $PROJECT"
