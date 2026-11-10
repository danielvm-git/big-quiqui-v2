# e13 — Test Plan (e13-wave-1b-primitives-and-templates)

<!-- story: e13s01 -->
**Skill:** `plan-tests` · **Date:** 2026-11-08 · **Risk level:** HIGH — 13 templates and 4 primitives, 17 P0 rows, one of them (spawned orphans) able to leak
every room. **Security row:** `SC-e13s03-P0-05` (map destinations resolve through the catalogue, F-3) comes
from `specs/security/CODEBASE_REVIEW_2026-11-08.md` and `specs/security/epics/e13/THREAT_MODEL.md`.
**Epic:** `specs/epics/e13-wave-1b-primitives-and-templates/` (9 stories, 44 scenarios; the four `e13s07` rows are withdrawn by the evidence-driven skip)
**Companion:** `specs/tech-architecture/TEST_PLAN_LATEST.md` (project-level 9-layer pyramid),
`specs/product/BUILDER_REUSE_MAP.md` (what survives the restart) and `CONVENTIONS.md` §Tests.

Scenario IDs follow `SC-<story>-<PRIORITY>-<NN>`. P0 must exist before the story is `done`; P1 is
expected; P2 is optional per time budget — except the rows marked **control**, which are never optional:
each of them proves a gate can fail (`plan-tests` inherits BUG-040's lesson: a gate that cannot fail is
decoration).

## 1. Coverage matrix

| ID | Level | Story | Scenario | Fails when |
|---|---|---|---|---|
| SC-e13s01-P0-01 | unit | e13s01 | a rub point outside the hull does not count | progress climbs from rubbing the background |
| SC-e13s01-P0-02 | unit | e13s01 | progress is the covered-area ratio and reaches 1.0 only when the area is done | a step finishes with the surface still dirty |
| SC-e13s01-P0-03 | unit | e13s01 | one loop channel per gesture, and zero after release | the rubbing sound outlives the gesture |
| SC-e13s01-P0-04 | unit | e13s01 | the hull is transformed at call time, after a rig move | a stale hull counts the wrong area |
| SC-e13s01-P1-01 | unit | e13s01 | `t34` reveals layers in the declared order and never reverses them | layers come back inside the step |
| SC-e13s01-P1-02 | e2e / geometry | e13s01 | the same rubs count the same at 1920x1080 and 2048x1536 | 4:3 counts differently |
| SC-e13s01-P2-01 | control | e13s01 | the mouse echo does not double-count a rub | one finger counts twice |
| SC-e13s02-P1-01 | unit | e13s02 | `any` completes on the first valid target | nothing completes |
| SC-e13s02-P1-02 | unit | e13s02 | `count_n` counts distinct targets only | tapping one object n times finishes the step |
| SC-e13s02-P1-03 | unit | e13s02 | a spent target replays its reaction without changing progress | a dead control teaches that touching stops working |
| SC-e13s02-P1-04 | unit | e13s02 | no timer ends the step | an auto-end timer (TutoTOONS `AddAutoEndTimer`) sneaks in |
| SC-e13s02-P2-01 | e2e / geometry | e13s02 | every tap target is >= 120 px at both aspects | a target is too small for a four-year-old |
| SC-e13s03-P0-01 | unit | e13s03 | pan clamps at both edges of the world | the world scrolls past its own boundary |
| SC-e13s03-P0-02 | unit | e13s03 | a drag past the tolerance cancels the tap it started on | panning opens a room |
| SC-e13s03-P0-03 | unit | e13s03 | a locked destination refuses with a sound and points at the next care step | a lock scolds or blocks silently |
| SC-e13s03-P0-04 | unit | e13s03 | every destination in the def resolves to a known scene id | a map door leads nowhere |
| SC-e13s03-P0-05 | unit | e13s03 | a map destination resolves through `SceneCatalog`; a value that is not in the catalogue is rejected and logged | a destination built as a path traverses out of `res://scenes` (F-3) |
| SC-e13s03-P1-01 | e2e / geometry | e13s03 | world size and clamp come from the def; both aspects reach every destination | 4:3 hides a destination |
| SC-e13s03-P2-01 | control | e13s03 | the template never reads the wallet (`get_coins`/`try_paying`) | a paid lock returns |
| SC-e13s04-P0-01 | unit | e13s04 | `t40` completes at the def threshold (0.9), not only at 100% | a child rubs a clean surface forever |
| SC-e13s04-P0-02 | unit | e13s04 | `t23` clears the layer and completes exactly once | erase completes repeatedly or never |
| SC-e13s04-P0-03 | unit | e13s04 | a completed step cannot be un-completed by more rubbing | work already credited is taken back |
| SC-e13s04-P0-04 | integration | e13s04 | soap, rinse and dry run as three steps from one def | the chain needs a scene script again |
| SC-e13s04-P1-01 | integration | e13s04 | the tray ignores taps while a rub owns the screen (`test_bathroom_rub_e2e`) | the tray steals the finger mid-gesture |
| SC-e13s04-P2-01 | unit | e13s04 | residue left below the threshold still completes and looks clean | perfection is required to advance |
| SC-e13s05-P1-01 | unit | e13s05 | an item snaps into its slot and the look is saved; the bin saves the empty slot | the child's look is lost |
| SC-e13s05-P1-02 | unit | e13s05 | an invalid item id is rejected before any save call | a crafted id reaches the save |
| SC-e13s05-P1-03 | unit | e13s05 | the title screen has exactly one interactive target | a second button (policy, subscription) appears |
| SC-e13s05-P1-04 | unit | e13s05 | the reward pays once and stays paid on re-entry | re-entering doubles the coins |
| SC-e13s05-P2-01 | unit | e13s05 | no template contains an ad branch (source scan) | `ShowVideo` returns from the TutoTOONS template |
| SC-e13s05-P2-02 | control | e13s05 | `ProgressManager` keeps its atomic write and its signatures | the save shape changed without a version bump |
| SC-e13s06-P2-01 | control | e13s06 | the evidence document exists and names both templates with a confidence level | the guess is never written down |
| SC-e13s06-P2-02 | control | e13s06 | the coverage claim in `SCOPE_LATEST.yaml` matches the build-or-skip call | prose overstates what is built |
| SC-e13s07-P1-01 | withdrawn | e13s07 | every object in a `t22` step answers its own touch | some objects are decoration |
| SC-e13s07-P1-02 | withdrawn | e13s07 | a `t22` step ends on counted touches, never when the sounds stop | an audio duration becomes a deadline |
| SC-e13s07-P1-03 | withdrawn | e13s07 | any input skips a `t3` beat and a declared reward is still given | skipping eats a gift |
| SC-e13s07-P2-01 | withdrawn | e13s07 | the template registry reports a consumer for both templates | a template is built with nothing using it |
| SC-e13s08-P0-01 | unit | e13s08 | lanes snap on release only, never mid-drag | the character jumps under the finger |
| SC-e13s08-P0-02 | unit | e13s08 | a seeded spawner replays the same sequence | a test cannot reproduce a spawn bug |
| SC-e13s08-P0-03 | unit | e13s08 | a caught object scores and a missed one does not | catching is invisible |
| SC-e13s08-P0-04 | control | e13s08 | zero orphan nodes across a long spawned run | spawned objects accumulate |
| SC-e13s08-P1-01 | unit | e13s08 | the template has no life, no screen shake and no projectile (source scan) | `DecreaseLife`/`ShootBullet` return |
| SC-e13s08-P2-01 | unit | e13s08 | a second consumer stub can use the Spawner unchanged | the modifier became `t50`-shaped |
| SC-e13s09-P1-01 | unit | e13s09 | one tap picks one prize and saves it | the pick is not remembered |
| SC-e13s09-P1-02 | unit | e13s09 | no second pick and no ad branch | `AddVideoAdReward` returns |
| SC-e13s09-P1-03 | control | e13s09 | the completeness gate fails when a template lacks a rule, a test or a consumer | the wave gate cannot fail |
| SC-e13s09-P1-04 | control | e13s09 | the scope percentage equals the number derived from the template table | the claim drifts from the table |
| SC-e13s09-P2-01 | unit | e13s09 | the prize set comes from the def and the template holds no table | a hidden table lives in code |

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
| unit | 31 | `game/tests/unit/test_*.gd` |
| control | 8 | fails-on-injection assertions inside the owning test file |
| e2e / geometry | 3 | `game/tests/integration/test_*_aspects.gd`, `*_scene.gd` |
| integration | 2 | `game/tests/integration/test_*.gd` |
| **total** | **44** | P0=17 · P1=17 · P2=10 · P3=0 (four `e13s07` rows withdrawn: P1=3, P2=1) |

The pyramid is deliberately bottom-heavy (unit) and the e2e rows are only the ones that need real
layout or a real child. Nothing in this epic is tested at the E2E level when a unit test could answer
the question — the exception is geometry, which cannot be faked.

## 4. Fixture architecture and isolation

| Fixture | Purpose | Isolation |
|---|---|---|
| Everything e12 established | `TestReset`, `FsmProbe`, `TouchSim`, `GeometryOracle`, `SceneDefFactory`, `ReactionRecorder`, `AudioKeyDouble`, `DefProbe` | unchanged |
| `ScrubSim` (new) | drive `ScrubGesture` with a path of points inside/outside a hull | no touch events needed for the counting logic |
| `SpawnerClock` (new) | advance a `Spawner` by injected delta, seeded | never reads wall time |
| `LayerSet` (new) | build foam/water/reveal layer stacks with declared areas | pure data, area known exactly |
| `OrphanProbe` (existing capability) | count nodes before/after a spawned run | the standard GUT orphan counter plus an explicit assert |

`Spawner` determinism is the one place a seed *is* the contract, so `SpawnerClock` exposes it and a test
asserts two runs with the same seed are byte-identical in object ids and lanes.

## 5. NFR verification

| NFR | Requirement | Verification command |
|---|---|---|
| Perf | the suite stays under 120 s once 13 templates exist | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit` (prints `Time`) |
| Memory | zero orphans after a long spawned run | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit -gselect=test_t50_lanes_e2e` |
| Determinism | the same seed replays the same spawn sequence | `-gselect=test_spawner` |
| Privacy | the diary carries ids only | `bash scripts/logs.sh audit --self-test` |
| Size | no new file over 300 lines, no function over 20 | `gdlint game/ && gdformat --check game/` + `-gselect=test_size_bars` |
| Typing | every new symbol strictly typed | `godot --headless --path game -s tools/type_gate.gd` |
| Geometry | both aspects for every new template's targets | `-gselect=test_rub_aspects`, `-gselect=test_tap_aspects`, `-gselect=test_map_aspects` |
| Hygiene | no ad branch, no paid lock, no Kitchen noun in a template | source scans inside the owning test file |

## 6. Anti-vacuity register

Every **control** row above is one of these. Failing to keep them is how a suite of 606 green tests
coexists with an unplayable game (the reason this restart exists):

| Gate | Prove it can fail by |
|---|---|
| id grammar over `assets/` | inject a file named `cenoura.png` into a temp dir and assert the scanner reports it |
| def validator | feed a def whose template id is `t99_missing` and assert a rejection, not a no-op |
| `consume_def` single-read | read twice and assert the second read is empty |
| no Kitchen noun in `t20` | add the word to the template in a fixture copy and assert the scan fails |
| no ad branch / no paid lock | add `show_video()` to a fixture copy and assert the scan fails |
| template completeness | delete a row from the table in a fixture copy and assert the gate fails |
| zero orphans | spawn without despawn in a fixture and assert the counter reports it |

## 7. Out of scope

- Wave 2 and 3 templates (e15, e16) — their own plans.
- Playfeel and delight: a test can prove the loop answers; only a child can prove it is fun.
- The 17 legacy rooms' test suites (deleted at e14s05).
- Audio quality / loudness on the device.

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
