#!/usr/bin/env bash
# story: e06s03
# ci-lint.sh — validate the GitHub Actions workflows locally, before they reach CI.
#
# wire-ci's hard gate is "CI that is untestable locally will break every cycle". This
# is that test: actionlint when available (syntax + expression semantics), plus the
# structural rules the portfolio CI/CD guide (danielvm-git/.github discussions/32)
# and GitHub's own hardening guidance require:
#
#   - every `uses:` is pinned to a 40-char SHA (a tag can be moved under you)
#   - every job declares `permissions:` (least privilege, not the default write token)
#   - every job declares `timeout-minutes:` (a hung job bills for 6 h by default)
#   - the workflow declares `concurrency:` (no duplicate pipelines on a ref)
#   - no `pull_request_target` (runs with a write token on untrusted input)
#   - no `secrets.*` inside `if:` (evaluated before masking)
#
#   bash scripts/ci-lint.sh          # exit 1 on any violation
set -uo pipefail
cd "$(dirname "$0")/.."
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh" 2>/dev/null || PYTHON=python3

FAILED=0
fail() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*" >&2; FAILED=$((FAILED + 1)); }
ok() { printf '  \033[1;32mok\033[0m   %s\n' "$*"; }

WORKFLOWS=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true)
if [ -z "$WORKFLOWS" ]; then
  fail "no workflows in .github/workflows/"
  exit 1
fi

if command -v actionlint >/dev/null 2>&1; then
  for wf in $WORKFLOWS; do
    if actionlint "$wf" >/dev/null 2>&1; then
      ok "actionlint $(basename "$wf")"
    else
      fail "actionlint $(basename "$wf")"
      actionlint "$wf" 2>&1 | sed 's/^/       /' | head -10
    fi
  done
else
  printf '  \033[1;33mNOTE\033[0m actionlint not installed — syntax unchecked (brew install actionlint)\n'
fi

$PYTHON - $WORKFLOWS <<'PY' || FAILED=$((FAILED + 1))
import re
import sys

import yaml

problems = []


def check(path: str) -> None:
    text = open(path).read()
    doc = yaml.safe_load(text) or {}
    name = path.split("/")[-1]

    if "pull_request_target" in (doc.get("on") or {}):
        problems.append(f"{name}: uses pull_request_target (write token on untrusted input)")

    if "concurrency" not in doc:
        problems.append(f"{name}: no top-level concurrency: (duplicate pipelines per ref)")

    for job_id, job in (doc.get("jobs") or {}).items():
        if not isinstance(job, dict):
            continue
        if "timeout-minutes" not in job:
            problems.append(f"{name}: job '{job_id}' has no timeout-minutes")
        if "permissions" not in job and "uses" not in job:
            problems.append(f"{name}: job '{job_id}' has no permissions: block")

    # every action must be pinned to a full SHA
    for lineno, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue  # a comment may legitimately mention `uses:`
        m = re.search(r"\buses:\s*([^\s#]+)", line)
        if not m:
            continue
        ref = m.group(1)
        if ref.startswith("./") or ref.startswith("docker://"):
            continue
        if not re.search(r"@[0-9a-f]{40}$", ref):
            problems.append(f"{name}:{lineno}: action not pinned to a SHA: {ref}")

    # secrets in expressions are masked only for shell/uses, not for `if:`
    for lineno, line in enumerate(text.splitlines(), 1):
        if re.search(r"\bif:\s*.*secrets\.", line):
            problems.append(f"{name}:{lineno}: secrets.* inside if: (evaluated before masking)")


for path in sys.argv[1:]:
    try:
        check(path)
    except yaml.YAMLError as error:
        problems.append(f"{path}: YAML parse error: {error}")

for problem in problems:
    print(f"  \033[1;31mFAIL\033[0m {problem}")
if problems:
    raise SystemExit(1)
print(f"  \033[1;32mok\033[0m   structure: pinning, permissions, timeouts, concurrency, no pull_request_target")
PY

echo
if [ "$FAILED" -eq 0 ]; then
  echo "CI LINT GREEN ($(echo "$WORKFLOWS" | wc -w | tr -d ' ') workflow(s))"
  exit 0
fi
echo "CI LINT RED — $FAILED problem group(s)"
exit 1
