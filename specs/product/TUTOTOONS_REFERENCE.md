# TutoTOONS reference — measured composition benchmark

<!-- story: e01s01 -->
<!-- story: e03s01 -->
**Skill:** observation pass (no device, no APK) · **Date:** 2026-11-05 · **Author:** coding agent
**Purpose:** turn "TutoTOONS-grade" into numbers this project can be held to, from public sources only.

> **Status:** pass 1 of 2. This document measures **static composition** from public store screenshots.
> It does **not** measure runtime feel — touch latency, frame rate, audio mix and haptics need a device
> (see [Not measurable this way](#not-measurable-this-way)). An engine-side pass with REA is stubbed at
> [Engine check](#engine-check-stub-before-any-rea-investment) and needs one Android device.

---

## Sample

Five titles, one per pillar of the vertical slice (not simply the five most downloaded):

| Slug | Title (source) | Why it is in the sample |
|---|---|---|
| `fluvsies` | Fluvsies – Cute Virtual Pets, iOS `24.1.6` | care/collect at scale — the flagship (100M+ installs on Android) |
| `smolsies` | Smolsies – My Cute Pet House, iOS `8.0.359` | pet care + house customisation — closest to our Casa hub |
| `kpopsies` | Kpopsies – My Unicorn Band, iOS `1.18.224` | hatch/collect/grow pacing — our CELEBRATE step (5 iPad frames only) |
| `dopples` | Dopples World: My Avatar Town, iOS `23.0.35` | current-generation feel (4.87★ on iOS, 2025 release) |
| `sbg-cleanup` | Sweet Baby Girl Cleanup 4, iOS | task-loop cadence — our FEED/BATH steps |

Two substitutions, recorded because otherwise the table lies:
- **Cleanup 5** is Android-only today, so the iOS build of **Cleanup 4** carries the task-loop cadence.
- The iOS **Kpopsies** listing is the *unicorn band* app, not the Android *Hatch Baby Unicorns* release, so
  its frame is treated as `collage/marketing` and contributes signals only, not geometry.

All-time Android ordering for context (Play only publishes buckets): Fluvsies 100M+, then Smolsies /
Kpopsies / Sweet Baby Girl Cleanup 5 at 50M+, then a long 10M+ tail (Hannah's High School Crush,
Jungle Animal Hair Salon, L.O.L. Surprise! Disco House, Sweet Baby Girl Summer Fun 2, My Baby Unicorn,
Dopples World). Full list in `specs/bugs`-adjacent notes is not duplicated here; the four `50M+`/`100M+`
titles are roughly a third of the studio's ~710M installs.

## Method

1. `python3 scripts/reference_shots.py fetch` — Apple's public lookup API (`itunes.apple.com/search`)
   returns metadata plus **8 iPad screenshots** per title; the image size segment is swapped to
   `2048x2732bb` and the result is **2048×1535** — the same 4:3 canvas as our iPad target.
2. `python3 scripts/reference_shots.py grid <slug> <shot>` — overlays a labelled 10 % horizontal /
   5 % vertical grid on a frame.
3. Each frame is **annotated by eye on that grid** (±2 %). Automated colour-mask measurement was tried
   first and rejected: on marketing composites the masks caught the potted plant as "the stage" and the
   caption border as "the character". Segmentation is not trustworthy on re-composed art; a labelled grid
   plus a human read is.
4. Pixels stay out of git (`reference/` is gitignored). Only numbers and source URLs are recorded.

**Every frame in this sample is a marketing composite**, not a device capture: each carries a caption
banner (bottom 10–20 %), and several are montages of multiple screens. Geometry read from them is
therefore *composition evidence*, not a spec of the shipped UI. Frames are tagged `room`, `hero` or
`collage` below.

## Measured frames

Canvas `2048×1535` (4:3). Ratios are of the canvas; `px@1080` converts to our logical 1920×1080 canvas.

### Fluvsies — `shot_6`, `room` (bath care room)

| Metric | Measured | Compare to us |
|---|---|---|
| Characters on screen | **4** | we ship 1 hero |
| Character heights | 18 %, 21 %, **30 %**, 23 % | our band is 55–65 % (single hero) |
| Feet / ground lines | 0.27, 0.50, **0.73**, 0.60 — depth stack | our contract: one line at 0.78 |
| Coin HUD chip | y 0.018–0.075, height 5.7 % | top inset **≈19 px@1080** vs our 36 px |
| Left action rail | x 0.02–0.10, y 0.02–0.45 | we use edge-anchored doors instead |
| Rail icon diameter | ≈4.8 % of width ≈ **96 px@1080** | our minimum is 120 px |
| Diegetic tools (brush, sponge) | 12–13 % of width ≈ 240 px@1080 | comfortably above 120 |

### Smolsies — `shot_3`, `room` (bath task)

| Metric | Measured | Compare to us |
|---|---|---|
| Characters on screen | **2** | — |
| Character heights | **44 %** (left), 35 % (right) | between our hero band and Fluvsies' room band |
| Feet lines | 0.63, 0.61 | single shared line ≈ our model |
| Back button | Ø **8 % ≈ 86 px@1080** top-left | under our 120 px minimum |
| Coin HUD chip | y 0.007–0.06 → top inset **≈7 px@1080** | our 36 px is 5× further in |
| Emotion bubble | ≈9 % × 8 %, y 0.10–0.19, above the head | our `WishBubble` — same placement logic |
| Drag tool (sponge) | ≈14 % of width; **ghost hand** drawn on it | we have no ghost-hand affordance |

### Dopples World — `shot_3`, `room` (doll-house park)

| Metric | Measured | Compare to us |
|---|---|---|
| Characters on screen | **16** (10 humans, 6 pets) | — |
| Character heights | foreground **39 %**, midground 17 %, background 15 % | strong depth scaling; we have one plane |
| Chrome | 2 corner buttons, Ø 7 % ≈ **76 px@1080** | under our 120 px minimum |
| Icon speech bubbles | 6 visible, each ≈8 % × 7 %, above the head | we ship one wish bubble |
| Currency HUD | none in this frame | we ship coin + tickets |
| Line style | flat 2D cartoon, **dark outlines** | our rule: no pure-black outlines, glossy shading |

### Sweet Baby Girl Cleanup 4 — `shot_3`, `room` (pool task)

| Metric | Measured | Compare to us |
|---|---|---|
| Helper character | right edge, ≥55 % of height, **partially cropped** | our hero is fully on-canvas |
| Home button | Ø 8 % ≈ **86 px@1080**, top-left | under our minimum |
| Forward / next | Ø 8 % ≈ 86 px@1080, bottom-right | our door pattern |
| Coin HUD chip | y 0.01–0.06 → top inset **≈11 px@1080** | our 36 px |
| Diegetic tools | 8–20 % of width | above our minimum |
| Dirt / "before" affordance | ≈10 % of width, saturated highlight | we use expression + bubble instead |

### Kpopsies — `shot_3`, `collage` (signals only, no geometry)

Countdown LED device top-right (hatch timer), an icon instruction bubble (brush + comb), a "NEW!" badge,
characters 20–40 % of height in 9-up collage. Recorded as *pattern evidence*: the collect loop is
timer-gated and taught by icon, never text.

## Cross-cutting findings

1. **Character scale is regime-dependent, and our band matches the hero regime.** Single-hero frames sit
   at ~55–65 %; multi-character rooms sit at 15–44 % with depth scaling. Our 55–65 % single-hero
   contract is correct for a care room that shows **one** child's character — keep e03–e10 single-hero.
2. **Our 120×120 px minimum is stricter than the shipped top-3.** Their persistent chrome measures
   76–96 px@1080. Ours sits at the top of the observed range, which is defensible for 4–7-year-olds;
   do not trade it down to match them.
3. **Our 36 px safe inset is 2–5× more conservative than their HUD** (7–19 px@1080). Keep 36 px: it costs
   nothing and the top-of-screen chip is the most mis-tap-prone region. Recorded so nobody "fixes" it.
4. **Icon-only bubbles above the head are the industry pattern**, not a flourish: every title expresses
   want/state as an icon bubble anchored to the head line. Our `WishBubble` head-line anchoring
   (BUG-013) is the same rule; it is validated.
5. **Ghost-hand affordance** (Smolsies) is the one teaching pattern we lack: a drawn hand on the
   draggable tool. Candidate for the e03 drag tutorial.
6. **Zero text in every gameplay frame.** Our "never require reading" rule is industry-standard, not a
   constraint we invented.
7. **Diegetic targets**: everything tappable is a drawn object in the scene, not a UI button. Matches our
   door/tool model; no evidence for a HUD-button-heavy design.

## Disposition — what we adopted, declined, and where it is gated

Every measured finding has exactly one home. This is the traceability from "seen in the wild" to
"asserted here"; a finding with no disposition is a finding nobody acted on.

| Finding | Disposition | Landed as | Enforced by |
|---|---|---|---|
| Hero 55–65 % of height, feet on the line | **already gated** (BUG-013) | `GeometryOracle` painted-rect contract | `TEST_PLAN` §3 row 2 · `EV-E03-01` |
| Icon bubble anchored to the head line | **gated + generalised** | `wish_bubble` group, clearance test per scene | `TEST_PLAN` §3 row 3 · `EV-E03-02` |
| Zero text in play frames | **already a convention** | scene-level no-text test | `TEST_PLAN` §3 row 6 · `EV-E03-03` |
| 36 px insets / 120×120 px targets (stricter than theirs) | **keep ours, recorded** | `TEST_PLAN` §4 declined list | `TEST_PLAN` §3 rows 4–5 · `EV-E03-04` |
| Multi-character rooms with depth scaling (15–44 %) | **declined** for the slice | `TEST_PLAN` §4 | revisit at e10 (friends on screen) |
| 76–96 px chrome, 7–19 px HUD insets | **declined** | `TEST_PLAN` §4 | prevents a future "alignment" pass |
| Flat dark-outline art | **declined** | `TEST_PLAN` §4 | `DESIGN.md` art direction |
| **Ghost-hand drag affordance** | **adopted, deferred to e04** | recorded in `state.yaml` open decisions | e04 story + a `model`-rubric eval when e04 starts |

Ghost-hand is deferred rather than opened as `e03s05` because e03 is released (`v0.4.0`); the bath
step has the same teach-without-words problem, so the affordance belongs where it will be designed,
not bolted onto a closed epic.

## What this does NOT license

Numbers and mechanics are fair to learn from; **pixels are not**. No asset, sprite, animation, audio
file, level or verbatim data table from these titles may enter this repo — that is copyright
infringement and it also violates our own art-provenance rules. The screenshots are fetched to a
gitignored `reference/` directory, measured, and discarded; the numbers here are our own annotations.

## Not measurable this way

- Touch-to-response latency, frame rate and hitches (needs device instrumentation).
- Easing curves, squash/stretch amplitude and audio ducking (needs 60 fps capture; the video pass is
  pass 2 and is still offline, but the store assets carry no `appPreviewUrls` for these titles).
- Session length, retention and economy pacing (needs telemetry we do not have and must not scrape).

## Engine check stub (before any REA investment)

REA (`morluto/rea`) can recover internal tuning constants (decay timers, reward tables, thresholds) that
no screenshot shows — but it needs the binary, so it needs one Android device you own. Before spending an
hour on setup, identify the engine from the APK:

```bash
unzip -l app.apk | grep -E "lib/|assets/META-INF/AIR|global-metadata"
```

| Signature | Engine | Verdict |
|---|---|---|
| `lib/*/libunity.so` + `assets/bin/Data/Managed/Metadata/global-metadata.dat` | Unity il2cpp | **REA worth it** — `docs/il2cpp-metadata.md` gives a class/method inventory to search for care-loop names |
| `lib/*/libCore.so`, `assets/META-INF/AIR/` | Adobe AIR | **REA no** — logic is ActionScript in a SWF; needs JPEXS, not JADX |
| `libcocos2dcpp.so`, `libmono.so`, `libgodot_*` | Cocos / Mono / Godot | partial — provider-specific |
| DEX-dominant | Kotlin/Java | yes, JADX path |

Known already from the package list: **Jungle Animal Hair Salon** and **Sweet Baby Girl Summer Fun 2**
are `air.com.tutotoons.*` — Adobe AIR, so out of REA's reach. Dopples World's engine is **unverified**;
one `unzip -l` settles it.

## Next pass

1. Video timing pass (offline): 60 fps gameplay capture → measure blink interval, squash duration,
   tap→reaction delay, care-step pacing. Needs a public gameplay video per title; store previews are
   empty for this sample.
2. Device pass: touch latency and frame pacing on the iPad target.
3. Engine pass: one title, one specific numeric question (e.g. "what is the wish-prompt interval?"), per
   the stub above.

## Provenance

| Slug | Track id | Version | Frames | Source |
|---|---|---|---|---|
| `dopples` | 6569248884 | 23.0.35 | 8 (measured = 3) | `Dopples World: My Avatar Town` via `itunes.apple.com/search` |
| `fluvsies` | 1504667963 | 24.1.6 | 8 (measured = 6) | `Fluvsies - Cute Virtual Pets` via `itunes.apple.com/search` |
| `kpopsies` | 1532725180 | 1.18.224 | 5 (measured = 3) | `Kpopsies - My Unicorn Band` via `itunes.apple.com/search` |
| `sbg-cleanup` | 1093069518 | 4.0.25 | 8 (measured = 3) | `Sweet Baby Girl Cleanup 4` via `itunes.apple.com/search` |
| `smolsies` | 1455222739 | 8.0.359 | 8 (measured = 3) | `Smolsies – My Cute Pet House` via `itunes.apple.com/search` |

Per-title ids and the exact image URLs are written to `reference/<slug>/metadata.json` by
`scripts/reference_shots.py fetch`; that directory is gitignored by design. Re-run the fetch to
regenerate them — the annotations above are the durable output.
