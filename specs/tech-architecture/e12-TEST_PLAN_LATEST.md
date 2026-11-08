# e12 — Test Plan (e12-builder-player-and-first-loop)

<!-- story: e12s01 -->
**Skill:** `plan-tests` · **Date:** 2026-11-08 · **Risk level:** HIGH — net-new subsystem (a player, a data model and a navigation path) with 22 P0 rows; the
legacy tree must stay green throughout. **Security rows:** `SC-e12s01-P0-01` (voice-key traversal, F-1),
`SC-e12s02-P0-08` (no code from data, F-2) and `SC-e12s05-P1-04` (node references, F-3) come from
`specs/security/CODEBASE_REVIEW_2026-11-08.md` and `specs/security/epics/e12/THREAT_MODEL.md`.
**Epic:** `specs/epics/e12-builder-player-and-first-loop/` (6 stories, 49 scenarios)
**Companion:** `specs/tech-architecture/TEST_PLAN_LATEST.md` (project-level 9-layer pyramid),
`specs/product/BUILDER_REUSE_MAP.md` (what survives the restart) and `CONVENTIONS.md` §Tests.

Scenario IDs follow `SC-<story>-<PRIORITY>-<NN>`. P0 must exist before the story is `done`; P1 is
expected; P2 is optional per time budget — except the rows marked **control**, which are never optional:
each of them proves a gate can fail (`plan-tests` inherits BUG-040's lesson: a gate that cannot fail is
decoration).

## 1. Coverage matrix

| ID | Level | Story | Scenario | Fails when |
|---|---|---|---|---|
| SC-e12s01-P0-01 | unit | e12s01 | a voice key is validated by its own grammar: `..`, `../`, `a/../b`, `vo..kitchen` are rejected, and the path is assembled only from validated segments | a dotted key becomes a traversal, or the resolver rejects every real line |
| SC-e12s01-P1-01 | unit | e12s01 | every art filename matches `\A[a-z0-9_]+\.(png | jpg)\z` |
| SC-e12s01-P1-02 | unit | e12s01 | every audio filename matches the id grammar and has a matching `.import` sidecar | a rename left the sidecar behind and the asset re-imports under a new uid |
| SC-e12s01-P1-03 | unit | e12s01 | `vo.<scene>.<line>` resolves to a stream; an unknown key returns `false` and logs `audio.missing_key` | a missing line crashes the room or locks input |
| SC-e12s01-P1-04 | unit | e12s01 | the locale defaults to `pt_BR` and a key path is built only from id-valid segments | a crafted key reads outside `assets/audio/voice/pt_BR` |
| SC-e12s01-P1-05 | integration | e12s01 | all 17 legacy scenes load with zero missing resources after the rename | a regenerated `.tscn` lost a texture reference |
| SC-e12s01-P2-01 | unit | e12s01 | no Portuguese asset path string remains in `game/scripts` or `game/tools` | a stale `res://` string survives to fail at runtime |
| SC-e12s01-P2-02 | control | e12s01 | the grammar test fails when a bad filename is injected | the new gate cannot fail (decoration) |
| SC-e12s02-P0-01 | unit | e12s02 | a valid `SceneDef` loads and exposes typed steps | a def loads with untyped or missing parameters |
| SC-e12s02-P0-02 | unit | e12s02 | an unknown template id is rejected with `scene.def_rejected` and a reason | a def silently runs with a no-op template |
| SC-e12s02-P0-03 | unit | e12s02 | an id failing `Ids.PATTERN` is rejected before any `res://` path is built | a crafted id reads a file outside `res://data/scenes` |
| SC-e12s02-P0-04 | unit | e12s02 | an empty step list or a missing background is rejected | a half-built scene reaches the player |
| SC-e12s02-P0-05 | unit | e12s02 | `request_def` drives the same FSM states as `request_scene`, with the same watchdog and pending slot | the new entry point grows a second transition path |
| SC-e12s02-P0-06 | unit | e12s02 | `consume_def` returns the def once and empty afterwards | a reload silently reuses a stale def |
| SC-e12s02-P0-07 | integration | e12s02 | the player scene boots from a def headless | the swap target and the payload channel disagree |
| SC-e12s02-P0-08 | control | e12s02 | neither `SceneDef` nor `StepDef` carries a path- or script-shaped field, and the template registry is a closed `const` map | a def becomes a code-loading vector (F-2) |
| SC-e12s02-P1-01 | unit | e12s02 | legacy `request_scene` keeps its rejections (`empty_path`, `same_scene`) and its `scene.<room>` slug | the diary vocabulary drifts and the PII contract breaks |
| SC-e12s02-P1-02 | integration | e12s02 | the gallery and MBT still enumerate all 17 legacy scenes while ids are added beside them | half the game leaves the coverage net |
| SC-e12s02-P2-01 | unit | e12s02 | `SceneCatalog.is_shipped` accepts both a legacy path and a scene id | a legacy room becomes unreachable from the tests |
| SC-e12s03-P0-01 | unit | e12s03 | the step machine rejects undeclared edges and treats a same-state call as a no-op | a step can enter a state the table forbids |
| SC-e12s03-P0-02 | unit | e12s03 | a step completes only when its template reports progress 1.0, and no step carries a deadline | a timer ends a step the child was still playing |
| SC-e12s03-P0-03 | unit | e12s03 | home exits from every state without penalty and without a second transition | quitting mid-step loses a reward or double-advances |
| SC-e12s03-P0-04 | integration | e12s03 | the chrome builds from a def and the dot count equals the step count | a room renders without a way out or without progress |
| SC-e12s03-P1-01 | e2e / geometry | e12s03 | both aspects: 0 px letterbox, rig proportions kept, every target >= 120 px | 4:3 strands the layout |
| SC-e12s03-P1-02 | unit | e12s03 | the reaction executor plays pose and sfx in the same frame; only `wait` defers | the answer arrives late and the loop feels dead |
| SC-e12s03-P1-03 | unit | e12s03 | `CareDotsBar` still mirrors the five care steps for the hub | the second source breaks the hub's display |
| SC-e12s03-P2-01 | unit | e12s03 | diary events carry ids only and the audit passes | prose or a path reaches the diary |
| SC-e12s03-P2-02 | control | e12s03 | zero orphan nodes after a full LOAD to EXIT | every room leaks a rig or a reaction node |
| SC-e12s04-P0-01 | unit | e12s04 | `single` consumes on the right receiver and returns the item on a miss | a miss eats the item |
| SC-e12s04-P0-02 | unit | e12s04 | `slots` accepts exactly one payload per slot and `free_place` reports a ratio inside the area | a slot takes two items or a drop lands outside the room |
| SC-e12s04-P0-03 | unit | e12s04 | exactly one `TouchDraggable` owns the finger for the whole drag | a second drag surface appears (ADR-004) |
| SC-e12s04-P0-04 | integration | e12s04 | no handler fires twice under `TouchSim` with the mouse echo, nor under a concurrent stream | one finger answers twice |
| SC-e12s04-P1-01 | unit | e12s04 | pose, sfx and the coin fly happen in the same frame | the reward arrives detached from the gesture |
| SC-e12s04-P1-02 | unit | e12s04 | a miss leaves the item enabled and at rest | a missed drop blocks the tray |
| SC-e12s04-P2-01 | control | e12s04 | INV-09 still reports `touch_draggable.gd` at 326 lines | the primitive grew the grandfathered file |
| SC-e12s05-P1-01 | unit | e12s05 | silence for the threshold shows exactly one hint | a hint fires while the child is playing |
| SC-e12s05-P1-02 | unit | e12s05 | any input hides the hand and starts the cooldown | the hand covers the target the child is reaching for |
| SC-e12s05-P1-03 | unit | e12s05 | a def without a hint block still runs the step | a missing hint is an error instead of silence |
| SC-e12s05-P1-04 | unit | e12s05 | a node reference that walks out of the room (`../`, `../../root`) is rejected and logged; ids resolve through a table the player registers | a def-supplied node reference escapes the room (F-3) |
| SC-e12s05-P2-01 | unit | e12s05 | the hand's rects track real layout at both aspects | the placeholder points at the wrong place on iPad |
| SC-e12s05-P2-02 | control | e12s05 | `DragHint` is `MOUSE_FILTER_IGNORE` and never completes a step | the hint solves the puzzle |
| SC-e12s06-P0-01 | unit | e12s06 | `repeat: 3` completes on the third correct drop | off-by-one ends the step early or never |
| SC-e12s06-P0-02 | unit | e12s06 | a wrong drop returns the piece and does not decrement progress | a miss subtracts work already done |
| SC-e12s06-P0-03 | unit | e12s06 | `kitchen.tres` declares every value the template reads | a template hardcodes a Kitchen noun |
| SC-e12s06-P0-04 | integration | e12s06 | three feeds credit `complete_step(FEED)` exactly once and exit home | the loop is credited twice or never |
| SC-e12s06-P0-05 | integration | e12s06 | re-entering after FEED is free play that credits nothing | a second visit double-credits the day |
| SC-e12s06-P1-01 | unit | e12s06 | the template file contains no Kitchen noun (source scan) | the next room is a copy-paste of this one |
| SC-e12s06-P1-02 | e2e / observed | e12s06 | a pre-reading child feeds three times unaided and asks to play again | the loop is correct and not delightful |
| SC-e12s06-P2-01 | e2e / geometry | e12s06 | the kitchen def lays out at both aspects with 0 px letterbox | the first data room breaks on the iPad |

## 2. Risk matrix

| Tier | Why these rows are here |
|---|---|
| **P0** | A wrong answer costs the child the loop or the save: the player machine, navigation, the def validator, the drag/tap surfaces, the bedroom/bathroom chains, spawner orphans. Every P0 has a RED test before its implementation. |
| **P1** | Core behaviour with a cheap repair: templates, templates' templates, hint timing, the title verb, the reward pay-once rule, the two evidenced templates. |
| **P2** | Display, layout sanity at 4:3, source-scan hygiene (no Kitchen noun, no ad branch, no paid lock). |
| **control** | A test that asserts *the gate fails* when fed a broken input. Named explicitly so a later refactor cannot quietly make the gate vacuous. |

## 3. Test level distribution

| Level | Count | Where |
|---|---|---|
| unit | 34 | `game/tests/unit/test_*.gd` |
| integration | 7 | `game/tests/integration/test_*.gd` |
| control | 5 | fails-on-injection assertions inside the owning test file |
| e2e / geometry | 2 | `game/tests/integration/test_*_aspects.gd`, `*_scene.gd` |
| e2e / observed | 1 | `specs/verifications/` (human record, not a test) |
| **total** | **49** | P0=22 · P1=18 · P2=9 · P3=0 |

The pyramid is deliberately bottom-heavy (unit) and the e2e rows are only the ones that need real
layout or a real child. Nothing in this epic is tested at the E2E level when a unit test could answer
the question — the exception is geometry, which cannot be faked.

## 4. Fixture architecture and isolation

| Fixture | Purpose | Isolation |
|---|---|---|
| `TestReset` (existing) | redirect saves, reset singletons | `user://test_progress.json`, deleted in `before_each` |
| `FsmProbe` (existing) | assert zero illegal transitions and zero unrecovered dwell timeouts | attaches per test |
| `TouchSim` (existing) | synthetic finger plus the `device == -1` echo | deterministic input, no timing |
| `GeometryOracle` (existing) | dual-aspect layout, 120 px targets, zero letterbox | sets viewport, restores after |
| `SceneDefFactory` (new) | one-line valid defs, plus a `broken(variant)` helper for each rejection case | pure in-memory Resources, no `res://` file needed |
| `ReactionRecorder` (new) | capture the order and timing of pose/sfx/voice/fx/coins without audio hardware | plain array, injected into the executor |
| `AudioKeyDouble` (new) | answer `vo.*` keys with a silent `AudioStreamWAV` and record misses | `AudioManager.stream_resolver` seam, no filesystem |
| `DefProbe` (new) | read a def and assert every value its template touches is declared | wraps the factory, fails with the field name |

No network, no database, no clock: this is a game with a local save and a local diary. The only
"external" surface is the filesystem (`user://`), which `TestReset` already redirects.

## 5. NFR verification

| NFR | Requirement | Verification command |
|---|---|---|
| Perf | the whole GUT suite stays under 90 s | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit` (prints `Time`) |
| Perf | a def loads and the player builds a room in under 250 ms headless | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit -gselect=test_scene_player` |
| Memory | zero orphan nodes after LOAD to EXIT | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit` (orphan count in the summary) |
| Privacy | the diary carries ids only | `bash scripts/logs.sh audit --self-test` |
| Size | no new file over 300 lines, no function over 20 | `gdlint game/ && gdformat --check game/` and INV-09 (`-gselect=test_size_bars`) |
| Typing | every new symbol strictly typed | `godot --headless --path game -s tools/type_gate.gd` |
| Geometry | 0 px letterbox at 1920x1080 and 2048x1536 | `-gselect=test_scene_player` (geometry oracle inside) |
| Traceability | every file tagged with its story | `bash scripts/trace-stories.sh --strict` |

## 6. Anti-vacuity register

Every **control** row above is one of these. Failing to keep them is how a suite of 606 green tests
coexists with an unplayable game (the reason this restart exists):

| Gate | Prove it can fail by |
|---|---|
| id grammar over `assets/` | inject a file named `carrot.png` into a temp dir and assert the scanner reports it |
| def validator | feed a def whose template id is `t99_missing` and assert a rejection, not a no-op |
| `consume_def` single-read | read twice and assert the second read is empty |
| no Kitchen noun in `t20` | add the word to the template in a fixture copy and assert the scan fails |
| no ad branch / no paid lock | add `show_video()` to a fixture copy and assert the scan fails |
| template completeness | delete a row from the table in a fixture copy and assert the gate fails |
| zero orphans | spawn without despawn in a fixture and assert the counter reports it |

## 7. Out of scope

- Anything that needs a real child (only `SC-e12s06-P1-02`, recorded by hand in `specs/verifications/`).
- Frame rate and cold start on the iPad (device-bound; the release gate owns it).
- Migrating the 17 legacy rooms onto the player — that is e14, and its own test plan.
- Retro-fitting the legacy scenes' tests: they are deleted with their scenes at e14s05, so testing them
  harder now would be work thrown away in three epics.

## 8. F.I.R.S.T. audit

| Property | How it holds here |
|---|---|
| **Fast** | the whole suite stays under ~90 s (63 s baseline); no test waits on real time — `manual_step` on every Fsm, `advance(delta)` instead of `await` |
| **Independent** | every test extends `QuiQuiTestCase`/`TestReset`; defs are built per test by a factory; no shared scene instance |
| **Repeatable** | every random source is seeded (`Spawner` takes a seed, `FoodCatalog.pick_tray` takes an RNG); geometry runs at both fixed aspects |
| **Self-validating** | assertions are predicates; no log scraping except the diary audit, which is its own command |
| **Timely** | each P0/P1 row is written RED in the story's first task, before its implementation |

## 9. Traceability

Every story of this epic carries its scenario IDs in `## 7. Named Test Scenarios` and in the
`scenarios:` list of its `-tasks.yaml`. `trace-stories.sh --strict` requires the `# story:` tag on
every file that implements a row; `traceability.py --check` requires code and a test per planned story.
