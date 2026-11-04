# ADR-007 — Centralized CI/CD (portfolio reusable workflow) and big-release as the release engine

<!-- story: e01s01 -->
- **Status:** Accepted
- **Date:** 2026-11-04
- **Supersedes:** the bespoke `.github/workflows/ci-cd.yml` (gate → package-ios → release)
- **Sources:** `danielvm-git/.github` discussion **#32** (central CI/CD v4.1.0), `danielvm-git/big-release` discussion **#72** (release automation)

## Context

The portfolio (28 repos) maintains a 3-tier CI/CD layer: consumer repo → reusable
workflows in `danielvm-git/.github` → GitHub Actions. Rule of the layer: **zero
duplication, one source of truth**, with a single-build boundary artifact
(`deploy-meta.json` = `{sha, ref, app_type}`) and CD decoupled from CI.

big-quiqui-v2 originally carried its own ~200-line pipeline. Two problems were
measured on it, and one gap in the portfolio was found:

1. `release` had `needs: [gate, package]` and `package` ran on macOS: the first main
   run sat **12+ minutes** in the macOS queue before it could cut a version.
2. The pipeline was repo-local, so every portfolio-wide fix (SHA pins, permissions
   model, concurrency semantics) would have to be re-applied here by hand.
3. The centralized layer had **no Godot workflow** (node, python, go, php, monorepo,
   static, swift, fullstack, pages-*), so a Godot repo could not comply.

## Decision

1. **Add the missing stack upstream.** `danielvm-git/.github` now publishes
   `test-build-release-godot.yml` (template + reusable mirror, v4.4.0) with inputs
   `godot_version`, `project_dir`, `export_preset`, `export_path`, `release_tool`,
   `bootstrap_gate`.
2. **This repo consumes it by copy (Option B), not by `uses:` (Option A).**
   `uses: danielvm-git/.github/.github/workflows/test-build-release-godot.yml@main`
   was tried first and produced a **startup failure with 0 jobs and no diagnostic**
   (run 41930344368; `actionlint` is clean on both the caller and the reusable file).
   `.github/workflows/ci-cd.yml` is therefore the template copied in with its
   `workflow_call` inputs inlined (v4.4.0, upstream sha `b48b6e00`), which the guide
   explicitly sanctions as the dual-consumption pattern. Re-sync when the upstream
   version bumps.
3. **The project keeps its gate.** The shared workflow runs `bash scripts/preflight.sh`
   when present, so gdlint/gdformat/strict-typing/GUT/PII/trace stay in this repo where
   they belong. The shared workflow never learns a project's conventions.
4. **big-release is the release engine** (`release_tool: big-release`), with
   `health` + `validate` pre-steps and the portfolio GIT identity.
5. **Versioning never waits on macOS.** `build` is a fast ubuntu job that emits
   `deploy-meta.json` (`app_type: godot`); the macOS `export` job runs in parallel and
   attaches its bundle to the release after big-release publishes it.
6. **Concurrency:** `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` —
   superseded PR runs are cancelled, an in-flight release on `main` never is.

## Consequences

- Upstream changes (action SHA pins, permissions model, concurrency) reach this repo
  without a commit here.
- The `test` job's failure detail now lives in the shared workflow, so a Godot-specific
  gate must be expressed in `scripts/preflight.sh` — which is where the story traceability
  and Zero-Test Guard already live.
- `bootstrap_gate: true` is a visible, one-line, self-expiring switch: e01s01 flips it to
  `false` and CI then enforces the Zero-Test Guard permanently.
- Duplication is now one file (~230 lines) that mirrors the upstream template instead of a
  bespoke pipeline; the copy is pinned to the upstream version in its header comment and
  re-synced on template bumps.

## Findings from the two sources

| Finding | Evidence | Consequence |
|---|---|---|
| The central layer validates templates mechanically | `scripts/validate-templates.sh` → `132 passed, 0 failed` with the new file | the Godot workflow is CI-checked upstream, not eyeballed |
| Job-scoped `permissions` are mandatory (Issue #34) | validator fails any `^permissions:` in `test-build-release-*` | worked around by job-scoped permissions in the new workflow |
| Unpinned actions and `ubuntu-latest` are rejected | `scripts/audit-workflows.sh` checks both | all actions SHA-pinned, `ubuntu-22.04` / `macos-14` runners |
| **`danielvm-git/big-release-action@v1` does not exist** | `gh api repos/danielvm-git/big-release-action` → **404** | disc #72's Step 1 cannot be followed verbatim; the portfolio already solves it with the curl install used in every `test-build-release-*` workflow — adopted here |
| disc #72's config sample enables the `git` plugin | big-release README documents GH006 rejections on protected branches | `.big-release.yml` keeps `github` only (no commit-back) |

## Alternatives rejected

- **`uses:` cross-repo invocation (Option A).** Preferred by the guide, tried first, and it
  does not start from this private repository: the run is created and immediately fails with
  zero jobs. Until that is understood upstream, Option B is the working path.
- **Keep the bespoke pipeline and "port" fixes later.** That is how the macOS-coupling
  bug happened in the first place.
- **Gate the release on the export artifact.** Delays every version by the macOS queue.

## Verification

```bash
# the workflow is the upstream template copy, not a bespoke pipeline
grep -q 'danielvm-git/.github' .github/workflows/ci-cd.yml
actionlint .github/workflows/ci-cd.yml
# release engine + rails
big-release validate
# the gate the shared workflow calls
bash scripts/preflight.sh
```
