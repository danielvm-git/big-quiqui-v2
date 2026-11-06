#!/usr/bin/env bash
# story: e01s01
# Single Preflight entry point for Coelinha QuiQui (CONVENTIONS.md §1).
#
#   bash scripts/preflight.sh              full gate — a GUT run that executes 0
#                                          scripts is a HARD FAILURE (Zero-Test Guard)
#   bash scripts/preflight.sh --fast       static stages only (L0/L0b/L3/L4/L5); the
#                                          pre-commit hook uses this, CI never does
#   bash scripts/preflight.sh --bootstrap  one-time house gate, before the first
#                                          story exists: 0 test scripts are allowed
#                                          and reported loudly. Recorded in
#                                          specs/state.yaml as lifecycle_phase.
#
# Every stage prints PASS/FAIL; the script exits non-zero on the first hard gate.
set -uo pipefail
cd "$(dirname "$0")/.."

MODE="full"
case "${1:-}" in
  --bootstrap) MODE="bootstrap" ;;
  --fast)      MODE="fast" ;;
  "") ;;
  *) echo "usage: bash scripts/preflight.sh [--fast|--bootstrap]" >&2; exit 2 ;;
esac

GODOT="${GODOT:-godot}"
GAME="game"
rc_all=0

stage() { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
pass()  { printf '\033[1;32m  PASS\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m  FAIL\033[0m %s\n' "$*"; rc_all=1; }
info()  { printf '\033[1;33m  NOTE\033[0m %s\n' "$*"; }

# run <label> <command...>  — output is kept in /tmp and shown only on failure
run() {
  local label="$1"; shift
  local log; log=$(mktemp)
  if "$@" >"$log" 2>&1; then
    pass "$label"
  else
    fail "$label"
    sed 's/^/        /' "$log" | tail -12
  fi
  rm -f "$log"
}

stage "L0 · GDScript lint + format (addons excluded)"
run "gdlint game/" gdlint "$GAME"/
run "gdformat --check game/" gdformat --check "$GAME"/

stage "L0a · engine import (game/.godot is gitignored)"
# Both the type gate and GUT resolve `class_name` through
# game/.godot/global_script_class_cache.cfg. On a fresh clone (CI, new machine)
# the cache does not exist yet, and without it `extends GutTest` cannot resolve:
# the type gate fails and GUT runs nothing while exiting 0. Import once, here.
import_log=$(mktemp)
if "$GODOT" --headless --path "$GAME" --import >"$import_log" 2>&1; then
  pass "project imported"
else
  fail "godot --import"
  tail -8 "$import_log" | sed 's/^/        /'
fi
rm -f "$import_log"

stage "L0b · strict typing (debug/gdscript/warnings/untyped_declaration=2)"
run "type_gate (every .gd must parse typed)" \
  "$GODOT" --headless --path "$GAME" -s res://tools/type_gate.gd

stage "L1 · GUT unit + integration"
if [ "$MODE" = "fast" ]; then
  info "skipped by --fast (static gate for the pre-commit hook; CI runs the full chain)"
else
gut_log=$(mktemp)
if "$GODOT" --headless --path "$GAME" -s addons/gut/gut_cmdln.gd -gexit >"$gut_log" 2>&1; then
  gut_rc=0
else
  gut_rc=$?
fi
# Positive evidence of execution, not just the absence of a failure: GUT can exit 0
# having printed nothing at all (observed on the ubuntu runner), which is exactly the
# silent-green mode this stage exists to prevent.
if ! grep -qE "Nothing was run|^(Tests|Passing|Failing|Scripts|Asserts)|Scripts[[:space:]]+[0-9]+" "$gut_log"; then
  fail "GUT produced no recognizable summary — cannot prove the suite ran (Zero-Test Guard, CONVENTIONS.md §1)"
  tail -6 "$gut_log" | sed 's/^/        /'
elif grep -q "Nothing was run" "$gut_log"; then
  if [ "$MODE" = "bootstrap" ]; then
    info "GUT executed 0 scripts — allowed once by --bootstrap (first story turns this into a failure)"
  else
    fail "GUT executed 0 scripts (Zero-Test Guard, CONVENTIONS.md §1)"
  fi
elif [ "$gut_rc" -ne 0 ]; then
  fail "GUT exited $gut_rc"
  grep -vE '^\s*at:|backtrace|^\s+\[[0-9]\]' "$gut_log" | tail -12 | sed 's/^/        /'
else
  pass "GUT suite"
fi
grep -E "^(Tests|Passing|Failing)|Scripts|Asserts" "$gut_log" | head -4 | sed 's/^/        /' || true
rm -f "$gut_log"
fi

stage "L3 · observability + PII redaction"
run "bash scripts/logs.sh audit --self-test" bash scripts/logs.sh audit --self-test

DIARY_DIR="$(bash scripts/logs.sh path 2>/dev/null || true)"
if [ -n "$DIARY_DIR" ] && [ -n "$(find "$DIARY_DIR" -name 'quiqui-*.jsonl' -maxdepth 1 2>/dev/null)" ]; then
  run "diary audit (real sessions)" bash scripts/logs.sh --dir "$DIARY_DIR" audit
else
  info "no local diary yet — the writer's contract is asserted by game/tests/unit/test_log.gd"
fi

stage "L4 · story traceability"
run "bash scripts/trace-stories.sh --strict" bash scripts/trace-stories.sh --strict

stage "L5 · specs schema (bigpowers contract)"
if [ -f scripts/validate-specs-yaml.sh ]; then
  run "scripts/validate-specs-yaml.sh (vendored)" bash scripts/validate-specs-yaml.sh
elif [ -f "$(npm root -g 2>/dev/null)/bigpowers/scripts/validate-specs-yaml.sh" ]; then
  run "validate-specs-yaml.sh specs" bash "$(npm root -g)/bigpowers/scripts/validate-specs-yaml.sh" specs
else
  info "skipped — no vendored validator and bigpowers not installed globally"
fi

stage "L6 · CI workflows (wire-ci, local)"
# Actionlint when installed; the structural rules (SHA pinning, permissions, timeouts,
# concurrency, no pull_request_target) always run. A pipeline that cannot be validated
# locally breaks every cycle, so this is a gate and not a note.
run "ci-lint.sh" bash scripts/ci-lint.sh

stage "L5b · release config (big-release)"
if command -v big-release >/dev/null 2>&1; then
  run "big-release validate" big-release validate
else
  info "skipped — big-release not on PATH (CI installs it in the release job)"
fi

printf '\n'
if [ "$rc_all" -eq 0 ]; then
  if [ "$MODE" = "bootstrap" ]; then
    printf '\033[1;32m✔ BOOTSTRAP GATE GREEN (mode: --bootstrap, 0 tests by design)\033[0m\n'
  elif [ "$MODE" = "fast" ]; then
    printf '\033[1;32m✔ STATIC GATE GREEN (mode: --fast, GUT skipped)\033[0m\n'
  else
    printf '\033[1;32m✔ PREFLIGHT GREEN\033[0m\n'
  fi
else
  printf '\033[1;31m✘ PREFLIGHT RED — do not proceed (CONVENTIONS.md §1 Always Green)\033[0m\n'
fi
exit "$rc_all"
