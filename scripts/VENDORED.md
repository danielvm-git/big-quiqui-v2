# Vendored bigpowers scripts

Source: bigpowers@2.93.1 (npm) — `scripts/` + `scripts/lib/` (transitive closure only).

We vendor instead of `bigpowers init` symlinking because `scripts/` here is
project-owned (`logs.sh`, `log_tool.py`, `setup.sh`, `trace-stories.sh`).
`bigpowers init` refuses to replace a user-owned `scripts/` dir, and the
scripts compute `REPO_ROOT` as `dirname $0/..` — so they must live in
`scripts/` for $REPO_ROOT to be this project.

Vendored: bp-yaml-set, bp-timing, record-cycle-time, sync-status-from-epics,
run-story-verify, land-branch + lib/{python-env,skill-common,fail-open-detect,
story-verify-memo,git-hours,record-cycle-time-lib,land-branch-push,
extract-story-verify}.

Deliberately NOT vendored: `trace-stories.sh` (name collision — ours is the
story-tag gate with project semantics; bigpowers' is the coverage-matrix
builder, add it as `scripts/trace-matrix.sh` only if gate-trace is adopted).

Re-vendor: re-run the copy loop in the Phase 1 script after a bigpowers bump.

## Added for pre-build compliance (2026-11-04)

- `scripts/lib/plan-consistency-check.sh` — the `plan-work` pre-build gate
  (CRITICAL/HIGH block code generation). Deps `fail-open-detect.sh` +
  `python-env.sh` were already vendored.
- `scripts/validate-specs-yaml.sh` — the bigpowers spec-schema validator.
  Lives at `scripts/` (not `scripts/lib/`) because it resolves
  `dirname $0/..` as the repo root and sources `lib/python-env.sh`.
  Vendoring it removed CI's dependency on a global `npm i -g bigpowers`.
- `scripts/compliance-pre-build.sh` + `scripts/compliance-capsules.sh` — project
  wrappers that prove the pre-build compliance claims mechanically.

## Known upstream defect (found during e01s01)

`record-cycle-time.sh append --file <path>` appends an OKF bundle whose second
document is Markdown prose after a `---` separator. PyYAML rejects the result
("mapping values are not allowed here"), so any `specs/**/*.yaml` it writes fails
the vendored spec-schema gate. Workaround: transcribe the tool's reported numbers
into the project ledger (`specs/cycle-times.yaml`) instead of appending.
