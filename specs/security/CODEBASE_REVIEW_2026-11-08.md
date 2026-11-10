# Security review — full codebase and specs backlog

<!-- story: e12s01 -->
**Skill:** `security-review` · **Date:** 2026-11-08 · **Scope:** the whole tree (`git rev-parse HEAD` present;
the "diff" is the entire repository, not a branch change) **plus** the planned backlog
`specs/product/SCOPE_LATEST.yaml` REQ-12…REQ-16.

**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network, single local save on the
child's iPad. That removes whole categories (SQLi, SSRF, auth bypass, session fixation, crypto) and
leaves four that matter here: **path/id construction**, **data → code**, **local state tampering**, and
**the CI/release chain**. The fifth — **PII** — is a compliance boundary this repo treats as security
(LGPD Art. 14 / Apple Kids).

**Threshold:** findings below 8/10 confidence are suppressed per the rubric. Where something is worth
doing but sits under the threshold, it is recorded in §6 as *hardening*, explicitly not as a finding.

## 1. What was checked and is clean (with the evidence)

| Area | Check | Result |
|---|---|---|
| Network | `HTTPRequest`/`HTTPClient`/`WebSocketPeer`/`StreamPeerTCP`/`ENetConnection` under `game/` | **0 in game code.** The only hits are in vendored `game/addons/gut/`, excluded from the export (`exclude_filter="res://tests/*,res://addons/gut/*"`). |
| Data → code | `eval`, `Expression`, `str_to_var`, `bytes_to_var`, `GDScript.new()` on non-constant input | **none** |
| Path from an id | every `res://`/`user://` path built from a variable | 40+ call sites, each preceded by `Ids.is_valid` (`\A[a-z0-9_]{1,64}\z`) or a stricter allowlist. `wish_bubble` uses `\Ares://assets/art/([a-z0-9_]+/)*[a-z0-9_]+\.png\z`, which was tightened after BUG-008 accepted `res://assets/art/../../x.png`. |
| Local state | `SaveData.from_dictionary` / `clamp_to_rules` / `_clean_*` | whole save clamped on read: coins/tickets/cycles `clampi`, id maps filtered through `Ids`, placements require ownership, ratios NaN-guarded before `clampf` (`clampf(NAN,0,1)` is `NAN`). |
| Save durability | `SaveFile` | `.tmp` → `rename_absolute`, `.bak` mirror, orphan `.tmp` detection. No path is ever built from save content. |
| Diary / PII | `Log` writer vs `scripts/log_tool.py` auditor | writer is **stricter** than the auditor: values flattened, id-checked, `msg` is an id, absolute paths / e-mails / 6-digit runs redacted. `preflight` L3 runs the audit on every commit. |
| Debug surface | `DevConsole` autoload | gated by `OS.is_debug_build()` (never paints in a release build) and **display-only** — no command input, so no privilege boundary. |
| iOS data exposure | `export_presets.cfg` | no `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace` override → `user://` (save + diary) stays inside the app sandbox, not reachable from the Files app. |
| Secrets | tracked tree | no `*.p12`, `*.pem`, `*.key`, `*.mobileprovision`, `*.keystore`, no `.env`, no private key block, no `api_key =`/`token =` literal. `app_store_team_id` is a public identifier, not a secret. `build/` is gitignored. |
| CI supply chain | `.github/workflows/*.yml` | **no `pull_request_target`**; every action pinned by full SHA with the version in a comment; `permissions: contents: read` by default, widened only on the release job; only `secrets.GITHUB_TOKEN` is used; `deploy.yml` re-validates the artifact (`sha` must equal `workflow_run.head_sha`, `ref` must be `main`) before trusting it (CI8). |
| Dev scripts | `scripts/*.py`, `scripts/*.sh` | `subprocess.run([...])` with list argv (no `shell=True`), no `eval`/`pickle`, `yaml.safe_load` only. `scripts/reference_shots.py` is the sole network user (iTunes search API, dev-only, invoked by no workflow). `setup.sh` installs from `requirements-dev.txt`, never `curl | sh`. |

Two structural controls are worth naming because they carry most of the weight:

1. **`Ids.PATTERN` is the single chokepoint.** Because it excludes `.` and `/`, an id cannot become a
   traversal. Every place that earned a bug about this (BUG-008, BUG-012) is now behind it.
2. **The save is cleaned on read, not trusted on write.** A tampered `progress.json` can inflate a
   cosmetic counter; it cannot mint an unowned item, place a piece the child does not own, or reach a
   path.

## 2. Findings — codebase (done work)

No finding reached the 8/10 threshold against the **shipped** code. The three items below this line are
all against the **planned** backlog, which is where the new attack surface is being created:

### F-1 · MEDIUM · confidence 9 · CWE-22 (path traversal) — voice keys will collide with the id grammar

**Location:** plan for `AudioManager.play_voice_key` — `specs/product/SCOPE_LATEST.yaml` REQ-12,
`specs/epics/e12-.../e12s01.md` §2.

**Description:** the plan asks for two things that cannot both be implemented naively. Voice is
addressed by a **key** (`vo.kitchen.intro`), and the project rule is that every id matches
`\A[a-z0-9_]{1,64}\z`. A key contains dots, so it is *not* id-valid; a resolver that either (a) validates
the key with `Ids.is_valid` rejects every voice line, or (b) interpolates the key into
`assets/audio/voice/pt_BR/%s.ogg` accepts `vo.../../../` shapes. The second is the natural way to make
the first "work", which is exactly why this is worth a finding before anyone writes it.

**Exploit scenario:** a crafted def (a tampered build, or the moment any def becomes user-writable)
carries `voice: "vo.kitchen../../../../ui/botao_play"`; the resolver normalises dots to `/` and loads an
asset outside the voice tree. Impact today is bounded — `res://` is immutable inside the IPA, so an
attacker who can edit a def already owns the device — but the resolver will be reused for any
user-writable source later, and the failure is silent.

**Recommendation:** a dedicated grammar, validated per segment, and a resolver that builds the path
from *validated* segments only:

```gdscript
# vo.<scene>[.<line>] — every segment id-valid, max 3 segments, no empty segment.
const VO_KEY: String = "\\Avo\\.[a-z0-9_]{1,32}(\\.[a-z0-9_]{1,32}){0,2}\\z"

static func is_voice_key(key: String) -> bool: ...
# path is assembled from segments that already passed the check, never from a split of raw input
```
Pinned by `SC-e12s01-P0-01` (`unit/test_voice_keys.gd`): the strings `..`, `../`, `a/../b`,
`vo.kitchen../../x` and `vo..kitchen` must all be rejected, and a rejected key must log
`audio.missing_key` and swap nothing.

### F-2 · MEDIUM · confidence 8 · CWE-94-adjacent (code from data) — `StepDef` must not be able to name a script

**Location:** plan for the scene data model — `specs/epics/e12-.../e12s02.md` §2/§3.

**Description:** the design states "scene data never contains code", but nothing in the plan makes that
*structural*. If `StepDef` grows a `script`/`resource_path` field, or if the template registry resolves
values that look like paths (`load` when `ResourceLoader.exists`), then a def file becomes a
code-loading vector. The registry is the one place that decides what runs, so it must be a closed
`const Dictionary` from template id to script, never a lookup by path.

**Exploit scenario:** a def with `template: "t99"` and a payload field naming `res://…/evil.gd`; a
permissive registry calls `load()` on it. Under the same device-ownership caveat as F-1, but the
control is free and permanent.

**Recommendation:** `StepDef` carries ids and numbers only (no path-shaped field); the registry is a
`const` map; an unknown id is a validation rejection. Pinned by `SC-e12s02-P0-08` (source scan: no
`script`/`path` field on the def classes, registry is const and closed) and the existing rejection test.

### F-3 · LOW-MEDIUM · confidence 8 · CWE-22-adjacent (node reference in a tree) — def-supplied node references

**Location:** plans for the hint layer (`e12s05.md` §2: `hint: { from: <node id>, to: <node id> }`) and
the map (`e13s03.md`: destinations open a scene).

**Description:** a node reference read from data and passed to `get_node()` resolves `..` and can walk
out of the room (`../../root/ProgressManager`). Likewise a destination string concatenated into
`res://scenes/%s.tscn` re-opens the traversal the ids rule closed.

**Recommendation:** resolve both through **tables the player builds**, keyed by declared ids: the player
registers its own node ids (`tray`, `receiver`, `rig`) at load, and map destinations resolve through
`SceneCatalog` — never a path built from the def value. Pinned by `SC-e12s05-P1-04` and
`SC-e13s03-P0-05`: a def carrying `../` is rejected with a log event and no navigation.

## 3. Threats specific to this product (why "no findings" is the wrong reading)

Three properties make the usual catalogue inapplicable, and each is a *different* risk that the tests,
not a scanner, must hold:

| Property | Consequence | Where it is held |
|---|---|---|
| 100 % offline, no accounts | no auth boundary to bypass; the "user" is a pre-reader and the "attacker" is a curious sibling with a file manager | `SaveData` clamping |
| One local save | integrity, not confidentiality, is the asset | `.tmp`/`.bak`, clean-on-read |
| No PII may leave, and little may exist | the diary is the only data the child generates | writer stricter than the auditor, L3 gate |

The realistic adversary model for this game is: **a child mashing the screen** (integrity of flow), and
**a device owner editing `progress.json`** (integrity of economy). Both are already bounded. There is no
adversary who can reach the app over a network, because there is no network.

## 4. Backlog review (todo) — e12…e16

Threat models for the two sliced epics are written: `specs/security/epics/e12/THREAT_MODEL.md` and
`specs/security/epics/e13/THREAT_MODEL.md`. The three later epics were reviewed for *new* surfaces only:

| Epic | New surface | Verdict | Note |
|---|---|---|---|
| **e14** — 17 rooms as data + the one removal commit | defs multiply; the English rename touches 135 files and 135 `.import` sidecars | **no new category** | the rename must not introduce an id that fails the grammar (add `SC-e14s01-P1-01` when e14 is sliced); the removal commit must not leave an orphan `res://` string (a scene-loads-clean test already covers it) |
| **e15** — wave 2 templates (`t55_find`, `t27_memory`, `t38_peekaboo`, `t51` already in 1b) | more def parameters; `t43_color_fill` in TutoTOONS writes a photo to storage (`PhotoGallery`) | **one to watch** | the scope already declines the photo gallery; keep the decline explicit in the template's adaptation rule so `TakePhoto`/`SaveToFile` cannot return with the template |
| **e16** — wave 3 (`t48_serve`, `t52_groom`, `t42_slice_cut`) | `t52` works on 50 strand objects; `t42` is a slicing scene | **no new category** | the declined verbs (shoot/slice/blade) stay declined for feel reasons, which doubles as the safety posture |

Cross-cutting backlog requirements this review adds (both are cheap now, expensive after e14):

1. **Every new id-shaped value that becomes a path** must be validated segment-by-segment, and the
   grammar must be *specific to the kind* (`VO_KEY`, `SCENE_ID`, `TEMPLATE_ID`), not one loose
   catch-all — a single `Ids.PATTERN` applied to a dotted key is how F-1 happens.
2. **No def field may hold a path, a script, or a node path.** If a future template needs one, it
   carries a *declared id* and the player owns the table.

## 5. Residual risk (accepted, with the reason)

| Residual | Why accepted |
|---|---|
| A tampered save can inflate coins/tickets up to the clamp | cosmetic, single-player, no purchase path, no leaderboard; the child's progress is not a security boundary |
| The diary persists on the device | it is the product's parent-facing feature, PII-audited and sandboxed (no file-sharing key in the preset) |
| `res://` is not integrity-checked inside the IPA | Godot`.pck` is not signed separately; anyone who can modify it owns the device. Tracked as a supply-chain note, not a code finding. |
| Dev tools (`reference_shots.py`) use the network | they are not shipped, not in CI, and not invoked by the game |

## 6. Hardening backlog (below the 8/10 threshold — recorded, not claimed)

| Item | Why it is not a finding | Cost |
|---|---|---|
| `.gitignore` does not cover `*.p12`, `*.keystore`, `*.mobileprovision`, `*.cer` | nothing is exposed today (rule 7: lack of hardening) | 4 lines |
| `ci-lint.sh` checks workflow secrets but nothing blocks `git add signing.p12` | same | one rule in `ci-lint.sh` |
| `application/code_sign_identity_release="Apple Development"` and an empty provisioning UUID | release-config completeness, not a vulnerability | set with the iPad release |
| `requirements-dev.txt` pinning | dependency hygiene is a separate scanner's job | low |

## 7. Verdict

- **Shipped code: no finding ≥ 8.** The offline design, the `Ids` chokepoint and the clean-on-read save
  are the reasons, in that order.
- **Backlog: three findings (F-1, F-2, F-3), all `medium`, all fixable by a requirement the plan can
  absorb before code exists.** Each one now has a scenario id and a capsule acceptance criterion, so
  8 → the fix is planned, not promised.
- **Not blocked:** nothing here blocks `kickoff-branch`. F-1 changes one acceptance criterion in e12s01
  (and that story's risk becomes P0), F-2 adds one scan to e12s02, F-3 adds one rejection test each to
  e12s05 and e13s03.
