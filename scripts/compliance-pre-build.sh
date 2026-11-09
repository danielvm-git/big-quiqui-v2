#!/usr/bin/env bash
# story: e01s01
# Pre-build bigpowers compliance gate — proves every skill that must run before the
# first line of code has its artifact, and that the artifacts still hold together.
#   bash scripts/compliance-pre-build.sh
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
chk() { # chk <label> <command...>
  local label="$1"; shift
  if "$@" >/tmp/bq-compliance.log 2>&1; then
    printf '  \033[1;32mPASS\033[0m %s\n' "$label"; pass=$((pass + 1))
  else
    printf '  \033[1;31mFAIL\033[0m %s\n' "$label"; fail=$((fail + 1))
    sed 's/^/        /' /tmp/bq-compliance.log | tail -4
  fi
}

echo "▸ planning artifacts (run-planning / discover phase)"
chk "survey-context → tech-stack.md"            test -s specs/tech-architecture/tech-stack.md
chk "scope-work → SCOPE_LATEST.yaml"            test -s specs/product/SCOPE_LATEST.yaml
chk "elaborate-spec → VISION_LATEST.yaml"       test -s specs/product/VISION_LATEST.yaml
chk "define-language → GLOSSARY_LATEST.yaml"    test -s specs/product/GLOSSARY_LATEST.yaml
chk "research-first → PRIOR_ART.md"             test -s specs/product/PRIOR_ART.md
chk "model-domain → Domain Model section"       grep -q '^## 6. Domain Model' specs/tech-architecture/tech-stack.md
chk "plan-release → release-plan.yaml"          test -s specs/release-plan.yaml
# e01-e09 were archived after their epics closed; the planning artifact still has to exist,
# it just no longer lives at the top level (BUG-062).
chk "slice-tasks → epic capsules"               bash -c 'test -d specs/epics/e01-tracer-title-and-foundation || test -d specs/epics/archive/e01-tracer-title-and-foundation'

echo "▸ pre-build planning (plan-work / plan-tests / assess-impact / security / evals)"
chk "plan-work → capsule consistency (11)"      bash scripts/compliance-capsules.sh
chk "plan-tests → e01-TEST_PLAN_LATEST.md"      test -s specs/tech-architecture/e01-TEST_PLAN_LATEST.md
chk "assess-impact → IMPACT_LATEST.md"          test -s specs/IMPACT_LATEST.md
chk "security-review → e01 THREAT_MODEL.md"     test -s specs/security/epics/e01/THREAT_MODEL.md
chk "run-evals → benchmarks/SCHEMA.md"          test -s specs/benchmarks/SCHEMA.md
chk "run-evals → benchmarks/e01.yaml"           test -s specs/benchmarks/e01.yaml
chk "grill-me → GRILL-e01-assumptions.md"       test -s specs/GRILL-e01-assumptions.md
chk "enforce-first → CONVENTIONS §Tests heading" grep -q '^## Tests (F.I.R.S.T' CONVENTIONS.md

echo "▸ cockpit schema (orchestrate-project / run-planning)"
chk "state.yaml → project_cycle"                python3 -c "import yaml,sys;d=yaml.safe_load(open('specs/state.yaml'));sys.exit(0 if d['project_cycle']['current_phase']==4 else 1)"
chk "planning-status → workflows schema"        python3 -c "import yaml,sys;d=yaml.safe_load(open('specs/planning-status.yaml'));w=d['workflows'];sys.exit(0 if len(w)>=18 and all(v['status']!='pending' for k,v in w.items() if k!='kickoff-branch') else 1)"
chk "specs schema (bigpowers validator)"        bash "$(npm root -g)/bigpowers/scripts/validate-specs-yaml.sh" specs

echo "▸ gates that must already bite"
chk "Zero-Test Guard present"                   grep -q 'Nothing was run' scripts/preflight.sh
chk "type gate present"                         test -s game/tools/type_gate.gd
chk "story verify extractor sees all tasks"     bash -c 'n=$(python3 scripts/lib/extract-story-verify.py . | wc -l); test "$n" -ge 129'

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf '\033[1;32m✔ PRE-BUILD COMPLIANCE: %d/%d checks pass\033[0m\n' "$pass" "$((pass + fail))"
else
  printf '\033[1;31m✘ PRE-BUILD COMPLIANCE: %d failed\033[0m\n' "$fail"
fi
exit "$fail"
