#!/usr/bin/env bash
# story: e06s03
# health.sh — is this checkout able to run, log and gate? One command, no side effects.
#
# Built for the wire-observability gate: the project already emits structured JSONL
# (game/scripts/autoloads/log.gd, audited by scripts/log_tool.py), so what was missing
# was a way to answer "is anything broken right now" without running the full gate.
#
#   bash scripts/health.sh           # human table, exit 1 on any failure
#   bash scripts/health.sh --quiet   # exit code only
#
# Idempotent: it creates nothing except the log directory, and never mutates the tree.
set -uo pipefail
cd "$(dirname "$0")/.."

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
FAILED=0
CHECKS=0

say() { [ "$QUIET" = 1 ] || printf '%s\n' "$*"; }
row() {
  CHECKS=$((CHECKS + 1))
  if [ "$2" = "ok" ]; then
    [ "$QUIET" = 1 ] || printf '  \033[1;32mok\033[0m   %-28s %s\n' "$1" "$3"
  else
    FAILED=$((FAILED + 1))
    printf '  \033[1;31mFAIL\033[0m %-28s %s\n' "$1" "$3" >&2
  fi
}

# ── toolchain ───────────────────────────────────────────────────────────────
if command -v godot >/dev/null 2>&1; then
  version=$(godot --version 2>/dev/null | head -1)
  case "$version" in
    4.7*) row godot ok "$version" ;;
    *)    row godot warn "$version (project targets 4.7)" ;;
  esac
else
  row godot fail "not on PATH (install Godot 4.7)"
fi
command -v python3 >/dev/null 2>&1 && row python3 ok "$(python3 -V 2>&1)" || row python3 fail "not on PATH"

# ── project ─────────────────────────────────────────────────────────────────
[ -f game/project.godot ] && row project ok "game/project.godot" || row project fail "missing game/project.godot"
[ -d game/.godot ] && row imports ok "game/.godot present" || row imports warn "run: godot --headless --path game --import"

# ── gate scripts ────────────────────────────────────────────────────────────
for script in scripts/preflight.sh scripts/trace-stories.sh scripts/logs.sh scripts/setup.sh; do
  if [ -x "$script" ]; then
    row "gate:$(basename "$script")" ok "executable"
  else
    row "gate:$(basename "$script")" fail "missing or not executable"
  fi
done

# ── git hooks ───────────────────────────────────────────────────────────────
hooks=$(git config --get core.hooksPath || true)
case "$hooks" in
  .githooks|*/.githooks) row hooks ok "$hooks" ;;
  "")                    row hooks fail "core.hooksPath unset (run scripts/setup.sh)" ;;
  *)                     row hooks fail "core.hooksPath=$hooks, expected .githooks" ;;
esac

# ── diary: writable, valid, redacted ────────────────────────────────────────
log_dir=$(bash scripts/logs.sh path 2>/dev/null | head -1 | sed 's/^[^:]*: *//')
if [ -n "$log_dir" ]; then
  if mkdir -p "$log_dir" 2>/dev/null && [ -w "$log_dir" ]; then
    row diary ok "writable ${log_dir/#$HOME/~}"
  else
    row diary fail "not writable: $log_dir"
  fi
  if bash scripts/logs.sh audit >/dev/null 2>&1; then
    row "diary:audit" ok "no PII, schema clean"
  else
    row "diary:audit" fail "audit failed — run: bash scripts/logs.sh audit"
  fi
else
  row diary warn "no log path yet (play once, or run the suite)"
fi

# ── offline invariant ──────────────────────────────────────────────────────
if grep -rqE 'HTTPRequest|HTTPClient|WebSocketPeer|OS\.shell' game/scripts game/tools 2>/dev/null; then
  row offline fail "network call found in game/ — this project is offline by construction"
else
  row offline ok "no network calls in game/"
fi

say ""
if [ "$FAILED" -eq 0 ]; then
  say "$CHECKS checks, 0 failures"
  exit 0
fi
say "$CHECKS checks, $FAILED failure(s)"
exit 1
