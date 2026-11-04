# Pre-build bigpowers compliance matrix

<!-- story: e01s01 -->
**Date:** 2026-11-04 · **Question answered:** *is every bigpowers skill that must run before
the first line of code run, with an artifact, and does it still hold?*

Mechanical proof — run this, not the prose:

```bash
bash scripts/compliance-pre-build.sh        # 20 checks
bash scripts/compliance-capsules.sh         # plan-consistency on all 11 capsules
```

The catalog holds 80 skills. They are **not** all pre-build skills: inventing an artifact
for a post-build skill would be theatre. Every skill therefore has one disposition below.

## A. Ran before implementation — artifact exists (21)

| Skill | Artifact | Verified by |
|---|---|---|
| `seed-conventions` | `AGENTS.md`, `CONVENTIONS.md`, `CLAUDE.md`/`GEMINI.md` symlinks | preflight `L4` |
| `using-bigpowers` | this matrix + `state.yaml` cockpit | `bash scripts/compliance-pre-build.sh` |
| `orchestrate-project` | `state.yaml → project_cycle` (phase 4, 1–3 complete) | compliance check |
| `run-planning` | `specs/planning-status.yaml` in the `workflows:` schema (18 keys) | compliance check |
| `survey-context` | `specs/tech-architecture/tech-stack.md` | assertion script |
| `scope-work` | `specs/product/SCOPE_LATEST.yaml` | assertion script |
| `research-first` | `specs/product/PRIOR_ART.md` | compliance check |
| `elaborate-spec` | `specs/product/VISION_LATEST.yaml` | assertion script |
| `define-language` | `specs/product/GLOSSARY_LATEST.yaml` | compliance check |
| `model-domain` | `tech-stack.md § 6 Domain Model` (11 terms) | compliance check |
| `grill-me` | `specs/GRILL-e01-assumptions.md` (4 rounds, 17 challenged assumptions) | compliance check |
| `plan-release` | `specs/release-plan.yaml` (+ version ladder) | assertion script |
| `slice-tasks` | 11 epic capsules, 43 stories | assertion script |
| `plan-work` | 43 `*-tasks.yaml` with `spec:`, `risk`, `allure`, `status: failing`; 43 story specs with `## Verification Script` | `plan-consistency-check` **CRITICAL=0 HIGH=0 MED=0** on all 11 |
| `plan-tests` | `specs/tech-architecture/e01-TEST_PLAN_LATEST.md` (21 scenarios) | compliance check |
| `assess-impact` | `specs/IMPACT_LATEST.md` (risk 3/10) | compliance check |
| `security-review` | `specs/security/epics/e01/THREAT_MODEL.md` (STRIDE + 4 findings) | compliance check |
| `run-evals` | `specs/benchmarks/SCHEMA.md` + `e01.yaml` (6 evals) | compliance check |
| `enforce-first` | `e01-TEST_PLAN_LATEST.md § F.I.R.S.T. audit` + `CONVENTIONS.md ## Tests (F.I.R.S.T` | compliance check |
| `wire-ci` | `.github/workflows/ci-cd.yml` → central reusable (ADR-007) | compliance check |
| `wire-observability` | `scripts/logs.sh` (path/tail/summary/audit) + `scripts/log_tool.py` PII redaction + self-test; commands documented in `AGENTS.md` | `logs.sh audit --self-test` |
| `session-state` | `specs/state.yaml` (`handoff`, `epic_cycle`, `metrics`, `project_cycle`) | compliance check |

> `wire-observability` is satisfied at the tooling layer; the `Log` autoload itself is
> **code**, delivered by e01s01 (its spec already fixes the JSONL schema + redaction).

## B. Runs inside each story (build-epic's 9 steps) — not before e01s01

| Skill | Step | Trigger |
|---|---|---|
| `build-epic` | conductor | first invocation is e01s01 |
| `kickoff-branch` | 3 | creates the worktree/branch — the *first action* of implementation |
| `develop-tdd` | 4 | RED-GREEN-REFACTOR |
| `verify-work` | 5 | UAT (developer-owned) |
| `audit-code` | 6 | ≥94% quality gate |
| `commit-message` | 7 | Conventional Commits + semver |
| `release-branch` | 8 | land via PR (epic train) |
| `security-review` | 0 | re-run per epic (e02…e11 threat models) |
| `trace-requirement`, `gate-trace` | before release of an epic | coverage matrix |
| `request-review`, `respond-review`, `simulate-agents` | optional QA | on demand |
| `fix-bug`, `investigate-bug`, `diagnose-root`, `quick-fix`, `validate-fix` | on a defect | `active_flow: fix_bug` |
| `maintain-wiki` | step 9b | OKF bundle refresh (not adopted yet — no wiki) |
| `inspect-quality` | folded into `verify-work` | conversational QA |

## C. Post-build / release phase

| Skill | Disposition | Reason |
|---|---|---|
| `generate-allure-report` | optional | no TestOps consumer; cycle times live in `specs/cycle-times.yaml` |
| `run-benchmark`, `stocktake-skills`, `evolve-skill` | portfolio-level | they audit bigpowers itself, not this product |
| `deploy`, `smoke-test`, `publish-package`, `harden-vps` | N/A | the deliverable is an offline iPad app; no server, no registry, no live URL |
| `gate-trace` | at epic close | needs shipped stories to trace |

## D. Not applicable to this project (explicit, not forgotten)

| Skill(s) | Why N/A here |
|---|---|
| `map-codebase` | greenfield: `tech-stack.md` was derived by `survey-context` |
| `migrate-spec`, `audit-plan`, `convert-legado` | no foreign spec to migrate |
| `extract-design`, `align-grid`, `archify` | web/UI-domain skills; the visual system lives in `DESIGN.md` + `specs/art/` |
| `deepen-architecture`, `plan-refactor` | require existing code; revisit after e02 |
| `design-interface` | deferred to e01s01: the `Fsm` interface is already fixed by ADR-001; a "design it twice" pass has no open choice left |
| `spike-prototype`, `find-way` | the unknowns were resolved by running the toolchain (see `GRILL-e01-assumptions.md`) |
| `hook-commits`, `guard-git` | superseded: `.githooks` (no Node) + the agent harness already blocks direct `main` commits |
| `change-request` | no new requirement has arrived mid-release |
| `compose-workflow`, `craft-skill`, `find-skills`, `search-skills` | authoring/discovery skills for the bigpowers package |
| `dispatch-agents`, `delegate-task`, `orchestration` | single-agent workflow by design (solo-git) |
| `terse-mode`, `simple-english`, `edit-document`, `write-document`, `organize-workspace` | writing utilities, not lifecycle gates |
| `visual-dashboard` | reporting UI; `specs/state.yaml` is the interface |
| `reset-baseline` | no benchmark loop to reset between |
| `define-success` | tombstone (merged into `plan-work`) |
| `deploy-*`, `publish-*`, `harden-*`, `smoke-test` | see C |

## The one honest gap

`kickoff-branch` is `pending` in `planning-status.yaml` by design: it **is** the first
action of e01s01 (build-epic step 3) and creating a worktree that sits idle would add
nothing. `handoff.next_skill: build-epic` covers it.

## Evidence trail

- `specs/IMPACT_LATEST.md` — risk 3/10, 42 downstream stories on the four helper APIs
- `specs/security/epics/e01/THREAT_MODEL.md` — T-E01-01..04 with owners
- `specs/tech-architecture/e01-TEST_PLAN_LATEST.md` — 21 scenarios, P0 first
- `specs/GRILL-e01-assumptions.md` — the 17 assumptions that were wrong and their fixes
- `specs/adr/ADR-007-centralized-ci-cd-and-big-release.md` — CI/release architecture
- `specs/benchmarks/e01.yaml` — 6 evals (5 code graders, 1 model grader, k=3)
