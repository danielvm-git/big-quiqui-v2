# TutoTOONS engine report — REA deep pass (24 titles, device-derived)

<!-- story: e01s01 -->
<!-- story: e03s01 -->
**Skill:** reverse-engineer-anything (REA `morluto/rea` 6.8.0) · **Date:** 2026-11-06 · **Author:** coding agent
**Purpose:** recover the *engine* behind the TutoTOONS catalogue so "TutoTOONS-grade" stops being a
screenshot guess and becomes a set of nameable, stealable mechanics. This is the engine-side pass that
`TUTOTOONS_REFERENCE.md` § *Engine check stub* said "needs one Android device".

> **Method:** 24 installed packages pulled in full over adb (4.5 GB, 162 split APKs) into gitignored
> `.rea/acq/`; engine fingerprinted per APK; IL2CPP `global-metadata.dat` decoded with
> `rea inspect-il2cpp-metadata` (version 31); type/method inventories recovered per title and
> cross-tabulated. Raw digests are in `.rea/report/digest-*.json` (gitignored). No pixel, audio, level
> or data table left `.rea/` — only names, counts and signatures are quoted here.

---

## 1. The one-line answer

**Every one of the 24 installed titles is Unity IL2CPP.** There is no Adobe AIR in the current
catalogue — including the `air.com.tutotoons.*` packages, which are a legacy `applicationId` fossil,
not an engine. The stub table in `TUTOTOONS_REFERENCE.md` is **wrong** and must be corrected.

| Fact | Value |
|---|---|
| Titles fingerprinted | 24 (all installed on the Tab A7 Lite) |
| Engine family | Unity IL2CPP — 24/24 |
| IL2CPP metadata version | 31 — 24/24 |
| Engine split | **Unity 2022.3.62f2** (22 titles) · **Unity 6 = `6000.0.71f1`** (2 titles) |
| The two Unity 6 titles | **Dopples World** (newest, 2025) and **Fluvsies** (flagship) |
| IL2CPP symbol scale | 17,663 types / 130,823 methods in Dopples; 9,104 / 61,742 in a small title |
| Shared engine assembly | `TutoTOONS.Base.dll` — present in **24/24** |
| Spine skeletal animation | `spine-unity.dll` — **24/24** |

The `libunity.so` version string `2018.3.0a1` that first appears is a **false positive** (an embedded
fallback constant). The authoritative version lives in `assets/bin/Data/globalgamemanagers` (the Unity
player version string), which is where `6000.0.71f1` and `2022.3.62f2` came from.

---

## 2. The shared framework — `TutoTOONS.Base.dll` (24/24)

This is the studio's engine, and it is a **service/monetization kernel, not a game loop**. The care
loop is per-title; the shared layer is what wraps it. Its 328 types break down as:

| Namespace | What it is | QuiQui 2 relevance |
|---|---|---|
| `TutoTOONS.AdService`, `.AdShowParameters`, `.AdsPerMinuteTracker`, `.Mediation`, `.AppConfig*` | Ad serving + **remote config** for ad-network priorities and A/B tests | **Decline** — we are ad-free and offline. No remote config either. |
| `TutoTOONS.TutoPulse`, `.AnalyticsHelper`, `.FirstSessionTracker`, `.ImpressionData` | Telemetry | **Decline** — "nothing leaves the device". |
| `TutoTOONS.Subscription.*` | Subscription gating | **Decline** for now (no IAP loop) |
| `TutoTOONS.SavedData`, `.SavedDataParserPairs`, `.FileWrapper`, `.PlayerPrefsWrapper` | **Local save with async serialization** (`RunSerializeTask`, `RunReadFileTask`, `RunDeserializeTask`), **AES encryption** (`TutoTOONS.Cryptography.AES`), and journaled files: `saved_data.json` + `saved_data_backup.json` + `saved_data_temp.json` | **Adopt the shape, not the crypto.** Their temp+backup write is the same idea as our `ProgressManager` atomic `.tmp` rename. Validates us; the missing piece is the **backup file**. |
| `TutoTOONS.Logging.TutoLogger`, `.LogConfig`, `.LogType` | Structured logger | **Mirrors our `Log` autoload.** We already do this. |
| `TutoTOONS.Utils.Debug.Console.*` | **Full in-game debug console** (`DebugConsole`, `ConsoleButton`, `ContentStats`, `ContentSavedData`, `SDKDebugging`) | **Adopt for dev builds.** We have `scripts/logs.sh` but no on-device console. |
| `TutoTOONS.PerformanceMonitor.*`, `FPSTrackerController` | **On-device FPS graph** + draggable overlay | **Adopt for dev builds.** Godot has the built-in debugger; an in-game overlay is still worth it. |
| `TutoTOONS.Indicators.*` | HUD badge system (`IndicatorController`, `IndicatorManager`, `IndicatorType`) | **Adopt** — we have no "NEW!" / unlock badge layer. |
| `TutoTOONS.DeepLinking.*` | Route-attribute deep links | Decline (mobile marketing) |
| `TutoTOONS.Utils.Observable\`1`, `ObjectPool\`1`, `TimeUtils`, `MathUtils`, `CanvasHelper`, `ZipUtils` | Utility | Note — an `Observable<T>` for reactive UI state is the one idea worth a look. |
| `TutoTOONS.IABrowser.*` | In-app browser | Decline (network) |
| `TutoTOONS.GameSnapshotController` | **Cloud save snapshots** | **Decline** (offline). But it proves they treat save as a first-class service. |

**Takeaway:** their engine is ~60% monetization/telemetry plumbing and ~40% save/logging/indicators.
The parts of that 40% that map to us (save, log, indicators, dev console) are exactly where we are
"raw", so the gap is not "we lack their engine" — it is "we lack their *production scaffolding*".

---

## 3. The care-loop archetype — Giggle Babies (Toddler Care)

Giggle Babies is the closest structural twin of our FEED→BATH→DRESS→PLAY→SLEEP loop, and its
`Assembly-CSharp` (1,959 types) is the richest care implementation in the sample. Its findings:

### 3.1 The need-state machine

`StateMachine.AnimalStateBehaviours` is a **behaviour-per-state FSM** with a generic
`StateBehaviour<T>` base and `AnimalBabyBehaviour.ChangeState(...)`. Twenty-eight animal states exist
(`AnimalHungryState`, `AnimalEatingState`, `AnimalSleepingState`, `AnimalPoopingState`,
`AnimalPettingState`, `AnimalWaitingForFoodState`, `AnimalTransitionPacifierState`, …), plus a parallel
`Puppy*` family.

**This is the same conclusion as our ADR-001, reached independently:** no boolean-flag clusters. Their
version is one class per state; ours is a table-driven `Fsm`. Ours is *more* rigorous — their
`StateBehaviour<T>` still scatters transition logic across classes. **Keep our `Fsm`; do not adopt
their per-state-class pattern.** The only thing worth stealing is the *granularity*: they model
"waiting for food", "stop for food", "eating", "pacifier" as separate states, which is a richer
interaction model than our coarse FEED step.

### 3.2 The care-need timer with escalation — the real find

```
HungerTimer: Init · SetNewTime · SetTime · Stop · TryShow · Update
             get/set_ReachedHalf · get/set_ReachedQuarter
```

Their hunger decays on a timer and **fires milestone events at quarter and half** (`ReachedQuarter`,
`ReachedHalf`), not just at empty. Our `WishBubble` signals binary want/no-want. **Adopt:** escalate the
wish bubble through quarter → half → full so the child sees urgency build before the care step opens.
This is a one-liner in our `CareLoopManager` and a real feel improvement, grounded in shipped evidence.

Companion types: `AnimalBabyStatus`, `BabyEmotionState`, `AnimalBabyEatState`, `TrySetAsHungry`.

### 3.3 Activities (our scenes) are drag→snap→react

- **FEED** — `Activity.Feeding.FeedingItem/FeedingItemManager`, `ToyFeedingChair`
  (`EquipToy`, `ItemOnBaby`, `OnEatingAnimComplete`, `OnItemDragged`, `GetAvailableItems`, `LockChair`),
  and a food taxonomy `KitchenFoodsData` with `KitchenFoodType`, `KitchenFoodTier`,
  `KitchenFoodReactionType` (food → reaction is data, not code).
- **BATH** — `Activity.Bathtub.*`: `Bubble`, `BubbleSpawner`, `StaticBubble`, `BubbleArea`,
  `ShampooSplatsController`, `BathShowerHead`, `BathPinwheel`, `BathtubColorController`, `ToyBathtub`.
  Bath = layered water-play particles + a palette controller, not a single animation.
- **DRESS** — `DressUpController` (42 methods): `AddDefaultClothes`, `ApplySet`, `ChangeCloth`,
  `TryBuyCloth`, `RemoveAllClothes`, `SaveAndExit` — clothes are **sets**, with `DressUpAnimationsController`
  picking a weighted idle animation per outfit.
- **TEETH (extended care)** — `TeethCleaning.*` (`TeethMonster`, `ToothbrushTool`, `ToothpasteTool`,
  `TeethCleaningStates`, `TeethCleaningController`) — a whole activity for one verb.

### 3.4 The hint/tutorial layer — our deferred ghost-hand, fully mapped

`HintManager` is a **queue** (`TryShowCurrentHintOrShowEnqueued`, `TryShowEnqueuedHint`, `ActivateHint`,
`StopHint`), and the hint taxonomy is rich:

| Type | Purpose |
|---|---|
| `Utility.HintHand` | The drawn ghost hand itself |
| `Hint.DragWorldToWorldHint` / `DragWorldToWorldListHint` | Teach drag between two world objects |
| `PulsatingHint` / `PulsatingWorldHint` | Attract attention to a target |
| `PictureHints` | Icon-only instruction (matches our no-text rule) |
| `MergeTutorialHints` | `ShowTapHint` / `ShowCircleHint` / `ShowDragHint` — tap vs drag teaching |
| `PopupMatchingHint` | `CanShowHint`, `TryShowHint`, `BeginCoolDown` — hint throttling |
| `HoverFeedback` / `HoverFeedbackController` | Highlight the object under the finger |
| `DragFromScreenToWorldHint` | Teach screen→world drag |

**Adopt.** This is the exact "ghost-hand affordance" `TUTOTOONS_REFERENCE.md` deferred to e04, now with
a name (`Utility.HintHand`), a queueing discipline (`HintManager`), and a throttle (`BeginCoolDown`).
Our e04 tutorial should be a *mini port* of HintManager + PulsatingHint + DragWorldToWorldHint, not a
bespoke bolt-on.

### 3.5 Meta-layer (what "more than care" looks like)

`Gardening.*` is a full secondary loop bolted on the care loop: `GardeningSeeds`, `GardeningPlants`,
`GardeningPests` (with `PestSpawnCondition`, `PestState`), `GardeningRecipes` (`MealRecipeDisplayPanel`),
and `GardeningHappinessIndicator`. It links back to care via `EatingActivityLinkPanel`. **Note, do not
adopt now** — it is the proof that their care loop is extensible by *data-driven activities*, which is
the architecture decision we should mirror (a new activity = data + one controller, not new engine).

---

## 4. Cross-title engine components (frequency in Assembly-CSharp)

These appear in 13–17 of 24 titles and are the de-facto "TutoTOONS component kit":

| Component | Shared methods (stable across titles) | QuiQui 2 meaning |
|---|---|---|
| `StatusBar` (13/24) | `AddRule · SetTimeProgress · UpdateShowHideOnStat · SaveState` | **Rule-table-driven** progress/status bar — same conclusion as ADR-001, in production |
| `CoinSystem` (13/24) | `AddCoins · TryPayingCoins · IsEnaughCoins · GatherCoin · CoinPulsate · ShowGetCoinsPopup` | Our coin HUD + reward path; note `IsEnaughCoins` is their typo, do not copy |
| `LevelUpSystem` (13/24) | `CalculateScoreToNextLevel · CalculateLevel · AddExp · IsLevelIncreased · SetProgressBarFillValue` | Their XP/level curve is a **table** (`SetSettingsValues`), not code |
| `ToolLock` / `LockObject` (13/24) | `SetLockType · TryUnlockWithMoney · TryShowAd · TryUnlock · SetAdWatch` | Lock taxonomy — we only need the coin-gate branch (no ads) |
| `CategoryController` (13/24) | `ActivateItem · CheckIfOneCategoryRemovesOther · SpawnCloneItem · AssignArrow` | Menu/scroll carousels |
| `ScrollView` (13/24) | `CreateImageBackground · CreateItemLock · FillScrollViewWithImages · SetupArrows` | The icon-grid component their whole UI is built from |
| `TemplateNNN*` (13/24, older titles) | `Template20Draggable · Template47Draggable · Template44Layer · Template46PlayCup · Template48Food · Template50Player` | **Numbered behaviour components** — content is data (`Template47Draggable` = a drag interactable with `FindMyTarget · ReleasedCorrect · WaitingForPickUp`) |
| `Slicer2D` + `Math2D` + `Polygon2D` + `Vector2D` (13/24) | full 2D polygon cut/geometry kit | Their "food slicing" minigame core; decline for us (no slicing loop) |
| `DrawLayer` / `EraseLayer` (13/24) | `Draw · CheckProgress · SetupCompletionCheck · SetEraseSize` | Reveal/erase minigame core |
| `PhotoGallery` (13/24) | `TakePhoto · SaveToFile · LoadPhotos · DisplayPhotos` | Screenshot-to-album feature; note (family sharing, but requires device storage) |
| `MovableTool` (13/24) | `OnBeginDrag · OnDrag · OnEndDrag · ReturnToStartPosition` | Their touch-drag primitive — mirrors our `TouchDraggable` |

**Reading:** the "engine" is a **component kit + numbered templates** in the older titles, and
**namespaced per-feature code** in the newer ones. Both are content-driven: scenes are built by
combining `TemplateNNN` components, and tuning (level curves, food reactions, lock prices) lives in data
tables, not code.

---

## 5. The architecture evolution (what "not raw" looks like)

| Era | Titles | Signature |
|---|---|---|
| **Animate/MovieClip** (oldest) | halloween, jungle hair salon 2, cleanup 6, pandalu | `TutoToons.ScriptedAnimations` — a **MovieClip imitator runtime** (`ScriptedAnimation` 62 methods, `IMovieClipImitator`, `Animation_blink/bounce/slide_wavy/random_eyes`, `Matrix3x3`) over Adobe-Animate-authored timelines, plus `Builder`/`BuilderImporter` (72+54 types) to import them |
| **Template component kit** (mid) | kpopsies, smolsies, gigglebabies, mybabyunicorn | `TemplateNNN*` numbered behaviours + `TutoTOONS.Builder.dll` (11/24) |
| **Spine + service assemblies** (current) | Dopples, Fluvsies, Princesses | **Unity 6**, `spine-unity` as the animation spine, clean split — Fluvsies ships `Fluvsies.dll` + `Fluvsies.Services.SavedDataRepository/Purchasing/Tracking/Enums`; Dopples ships 3,993 Assembly-CSharp types under `DopplesWorld.*` |

Fluvsies is the cleanest architecture in the catalogue: a thin `Fluvsies.dll` + explicit
`Fluvsies.Services.*` — i.e. they refactored their own monolith into a service layer. That is the
"not raw" end-state, and it matches our five-autoload plan in spirit.

### Delivery-packs evidence (Play Asset Delivery)

Dopples ships **52 `split_scene_*` packs** (one per room: `split_scene_hospitalsecretlab`,
`split_scene_yumyummarketmain`, …) + `split_textureassetbundle` + `split_sounds` + `split_shared`.
Fluvsies ships 25 (`split_all_atlases`, `split_music_tracks`, `split_sfx`, `split_room_shared`).
**Meaning:** they stream scenes as content packs, so a scene = data + one controller + a delivery pack.
Our Godot `.tscn` scene-per-epic is the same shape — the lesson is that *content* (atlas, sfx, room
data) should be separable from *logic*, which we already do via `build_*_scene.gd`.

---

## 6. What this means for QuiQui 2 — adopt / decline / already-have

### Adopt (concrete, grounded in shipped evidence)

1. **Wish escalation** — quarter/half/full milestones on the need timer (`HungerTimer.ReachedQuarter/Half`)
   → `CareLoopManager` + `WishBubble`. Cheapest high-value change.
2. **Hint layer** — port `HintManager` (queue + `BeginCoolDown` throttle) + `PulsatingHint` +
   `DragWorldToWorldHint` + `Utility.HintHand` for e04. This *is* the deferred ghost-hand, now specified.
3. **Dev scaffolding** — an in-game debug console + FPS overlay (`TutoTOONS.PerformanceMonitor`,
   `DebugConsole`) for our dev builds, beside `scripts/logs.sh`. Closes our "raw on observability" gap.
4. **Save backup file** — `saved_data.json` + `.backup` + `.tmp` journal; we already do `.tmp` rename in
   `ProgressManager`, add the backup read-path for corruption recovery (pairs with ADR-005 migration).
5. **Indicator/badge layer** — `IndicatorManager`/`IndicatorType` for unlock "NEW!" badges (pairs with the
   already-shipping `moedinha.png`/`estrela.png` reward reveal).
6. **Data-driven activities** — their `KitchenFoodsData` (`FoodType/Tier/ReactionType`) and
   `SetSettingsValues` level tables are the proof that care-step tuning must be data, not code. Fold into
   our table-driven FSM convention (ADR-001) explicitly for FEED/BATH tuning.

### Decline (on principle, not taste)

- The **ad/mediation/telemetry/remote-config/subscription** half of `TutoTOONS.Base.dll` — violates our
  ad-free, 100% offline, no-telemetry rules.
- **Cloud snapshots** (`GameSnapshotController`) — network + server dependency.
- **`Slicer2D` / `DrawLayer` / `EraseLayer`** minigames — no slicing/erase loop in our slice.
- **Per-state-class FSM** — keep our table-driven `Fsm`; do not adopt their `StateBehaviour<T>` scatter.
- **Spine** — we are Godot/GDScript; `spine-unity` does not transfer. (Their *content* approach does.)

### Already have (validated, do not "fix")

- `Log` autoload ↔ `TutoLogger`.
- `ProgressManager` atomic `.tmp` rename ↔ their `saved_data.json` + `_temp.json`.
- `Fsm` table-driven transitions ↔ their rule-table `StatusBar` / state behaviours (same ADR-001 conclusion).
- `TouchDraggable` (mouse-echo filter) ↔ `MovableTool` / `Template47Draggable`.
- No-text play ↔ `PictureHints` / icon-only bubbles (every measured title).

---

## 7. The correction to file against the reference doc

`TUTOTOONS_REFERENCE.md` § *Engine check stub* says:

> "`air.com.tutotoons.*` → Adobe AIR → REA no … needs JPEXS, not JADX."

**This is refuted.** Both `air.com.tutotoons.app.*` packages present on the device (Power Girls Super
City, Sweet Baby Girl Halloween Fun, Animal Hair Salon 2 Jungle) are **Unity 2022.3.62f2 + IL2CPP**.
The `air.` prefix is a legacy package-name relic. The engine-detection table's AIR row should be struck,
and Dopples World's "unverified" engine is now verified: **Unity 6**.

---

## 8. Raw areas in QuiQui 2 (what this pass exposed)

1. **No care-need escalation** — binary want/no-want only (§6.1).
2. **No hint/tutorial layer** — the ghost-hand is still a TODO, and now we know the full taxonomy (§6.2).
3. **No on-device dev console / perf overlay** — observability is CLI-only (`scripts/logs.sh`) (§6.3).
4. **No save backup/repair path** — atomic rename exists, recovery does not (§6.4).
5. **No badge/indicator layer** for unlocks (§6.5).
6. **Tuning constants are not yet first-class data** — level curves / reaction tables / prices live in
   code today; their shipped answer is data tables (§6.6).

Everything else we have is either already at or above their bar (FSM discipline, mouse-echo filtering,
no-text UI) or correctly out of scope (monetization, cloud, telemetry).

## Provenance

- Device: Samsung Galaxy Tab A7 Lite `SM-T220`, Android 14 (SDK 34), arm64-v8a, USB-adb.
- 24 packages pulled via `rea pull-adb-package` → `.rea/acq/` (4.5 GB, 162 APKs), gitignored.
- IL2CPP metadata decoded with `rea inspect-il2cpp-metadata` (version 31); Dopples = 132 images /
  17,663 types / 130,823 methods; Giggle Babies = 1,959 Assembly-CSharp types; Fluvsies =
  `Fluvsies.dll` + `Fluvsies.Services.*` (no Assembly-CSharp).
- Raw digests: `.rea/report/digest-*.json` (gitignored). Re-derivable from the device with
  `bash scripts/pull-all.sh` + `python3 scripts/deep_pass.py` (cross-title rollup:
  `python3 scripts/deep_pass_aggregate.py`; single-assembly dump: `scripts/deep_pass_dump_base.py`).
