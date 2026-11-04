# Evals — schema and conventions

<!-- story: e01s01 -->
**Skill:** `run-evals` · Eval-Driven Development for this project.

An eval is a *capability* claim with a grader. Two grader kinds are allowed:

| Kind | Grader | Pass rule |
|---|---|---|
| `code` | a runnable command with an exit code (or a parsed assertion) | exit `0`, and the command is not fail-open (`scripts/lib/fail-open-detect.sh` rules) |
| `model` | an explicit rubric with numbered pass/fail criteria | **all** criteria pass; a criterion without a binary answer is rejected at review |

## File layout

```text
specs/benchmarks/
├── SCHEMA.md          # this file
├── e01.yaml           # one file per epic
└── ...
```

## Entry schema

```yaml
epic: e01
kind: capability        # capability | regression
evals:
  - id: EV-E01-01
    claim: "Fsm rejects undeclared transitions"
    story: e01s01
    grader: code
    run: godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit
    must_match: "SC-E01-P0-01"       # the GUT scenario that proves it
    pass_when: "exit==0 and scenario present in GUT output"
  - id: EV-E01-02
    claim: "The playable scene is reachable by tap without reading"
    story: e01s05
    grader: model
    rubric:
      1: "Tapping the Play button enters the scene with no text prompt"
      2: "The button's hit box is >= 120x120 px in both aspects"
      3: "Audio feedback starts within one frame of the tap"
    pass_when: "all rubric items yes"
```

## Rules

1. **Define before building.** An eval that is written after the code is a description,
   not a test.
2. **No fail-open graders.** A command that cannot exit non-zero (e.g. `echo ok`,
   `|| true`) is rejected — the same detector that guards `verify:` guards evals.
3. **Regression evals are permanent.** When a bug fix lands (`fix:`), add a regression
   eval that fails on the pre-fix commit.
4. **pass@k is recorded, not inferred.** For model graders, record `k` and the observed
   pass count in the cycle time entry; never report a single run as a capability.
5. **Eval ≠ unit test.** Unit tests prove code behaviour; evals prove the *product claim*
   (a child can play it). Both are required; neither substitutes for the other.
