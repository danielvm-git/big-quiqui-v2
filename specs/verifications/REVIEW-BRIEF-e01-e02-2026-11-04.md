# Review brief — e01/e02 fix cycle (audit response)

<!-- story: e01s05 -->
<!-- story: e02s04 -->

You are a **code reviewer** with a clean context. You did not write this code and you have not seen
the author's reasoning. Review the changes in this working tree and report findings.

**Read-only.** Do not modify, create or delete any file. Do not run `git add`, `git commit`,
`git checkout`, `git stash` or anything else that changes state. Reading files and running the
verify command is all you need.

## What the change set is

Project: **Coelinha QuiQui** — an offline Godot 4.7 care game for pre-reading children (ages 4–7),
iPad-first, PT-BR voice, no network, no ads, no telemetry. GDScript with mandatory static typing.

Two epics had already shipped (`e01` foundation + title scene, `e02` casa care hub). A full
`audit-code` pass then found 18 issues: layout, telemetry payloads, economy constants, id contract
drift, duplication, gate blind spots, pre-`_ready` crashes and loose path validation. This change set
is the audit response: it fixes them, adds the missing regression tests, extracts four shared
helpers, and regenerates both `.tscn` scenes from their builder scripts.

Run `git diff` and `git status` to see everything. Read these first:

- `CONVENTIONS.md` (engineering rules — strict typing, `Fsm` for every state machine, `Control` roots,
  mouse-echo filtering, atomic saves, F.I.R.S.T. tests, 120×120 px minimum hit target)
- `DESIGN.md` (layout: 1920×1080 base, 4:3 iPad `expand`, QuiQui 55–65 % of height with feet at
  78 %, edge anchoring or a centred `SafeStage`, 36 px safe insets)
- `specs/adr/ADR-001…008` (state machines; viewport; rig layering; touch; save model; vertical
  slicing; **ADR-008: edge-anchored responsive composition**)
- `specs/bugs/BUG-001…012` + `specs/bugs/registry.yaml` (what each bug claimed and what the fix claims)
- `specs/verifications/AUDIT-e01-e02-2026-11-04.md` (the audit findings F1–F18)
- `specs/verifications/FIX-e01-e02-2026-11-04.md` (the claimed evidence)

## Verify command

```bash
bash scripts/preflight.sh
```

It runs gdlint, gdformat --check, an engine import, a strict-typing gate over `game/scripts`,
`game/tests` and `game/tools`, the full GUT suite, a PII audit of the play diary, story-tag
traceability and the specs schema. Run it and report the result verbatim.

## Review for

1. **Correctness** — does each fix actually close its bug, and does it break anything else? Pay
   attention to the anchor maths and the regenerated scenes (`game/scenes/*.tscn`), the
   `SquashSpring` time-stepping, and the `LogSink` extraction.
2. **Regression tests** — does each test fail if the bug is reintroduced? Name any test that would
   still pass with the bug present (vacuity), and any fixed behaviour with no test.
3. **CONVENTIONS.md compliance** — strict typing, `Fsm` usage, mouse-echo filtering, no `Node2D`
   scene roots, `# story: eNNsYY` tags, atomic saves.
4. **Test quality (F.I.R.S.T.)** — isolation (no production save access), determinism (no wall-clock
   waits), behaviour-level assertions rather than implementation details.
5. **Design** — is there a simpler or more robust shape? Specifically: is `Ids` the right owner for
   the id contract while `Log` keeps its own pattern? Is the duplicated ratio constants set (builders
   vs oracle) a problem? Is `CareSteps` in the right layer?
6. **Edge cases** — 4:3 vs 16:9 vs a resized desktop window; a scene mounted before autoloads are
   ready; a corrupt or absent save; a missing art file; rapid taps.
7. **Security / privacy** — no network, no telemetry, PII never reaches `user://logs/quiqui-*.jsonl`,
   no path traversal from an id.
8. **Refactoring smells** — explicitly name any Fowler smell you find: Mysterious Name, Duplicated
   Code, Feature Envy, Data Clumps, Primitive Obsession, Message Chains, Middle Man.

## Output format (end your reply with exactly this)

```
VERDICT: PASS | FAIL
MUST-FIX:
- <file:line> — <what is wrong and why it matters>   (or "none")
SHOULD-FIX:
- <file:line> — <what and why>                        (or "none")
CONSIDER:
- <file:line> — <what and why>                        (or "none")
SCORE: <0-100, computed as 100 * (total_items - must_fix - should_fix) / total_items>
VERIFY: <the preflight result line you observed>
```

`VERDICT: PASS` only if you have zero must-fix items. Do not be agreeable: if the change set is
sound, say so with a high score; if it is not, name the failure precisely.
