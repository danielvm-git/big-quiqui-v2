# Coelinha QuiQui — TutoTOONS Visual & Interaction Design System (`DESIGN.md`)

<!-- story: e01s01 -->

## 1. Aesthetic North Star: Glossy Candy-Colored 2D ("TutoTOONS Benchmark")
- **Reference Benchmark:** *Kiki & Fifi Pet Friends*, *My Baby Unicorn*, *Moy / My Talking Angela* — vibrant, saturated pastel-candy surfaces with soft 3D volume, specular highlights, and immediate tactile joy.
- **Line Art:** Thick, smooth, rounded outlines tinted in deep warm hues (chocolate brown `#4A2511`, plum `#5B1E4E`, deep berry `#6E1837`, or navy `#1B365D`). **NEVER use pure `#000000` black outlines.**
- **Zero Text Rule:** Pre-reading children (ages 4–7) navigate 100% via oversized glossy icons, contextual character expressions, wish bubbles (`balao_desejo.png`), and Brazilian Portuguese family voice prompts.

---

## 2. Color Tokens
| Token | Hex | Usage |
|---|---|---|
| `candy_pink_primary` | `#FF6FAE` | Primary CTA frames, heart particles, affection highlights |
| `sunny_gold` | `#FFD13B` | Coin badges, star rewards, celebration rays |
| `mint_fresh` | `#4CE0B3` | Positive completion states, garden accents |
| `lavender_dream` | `#B983FF` | Closet/bedroom accents, magic sparkles |
| `sky_bubble` | `#5AC8FA` | Bathroom water/foam accents, clean highlights |
| `warm_cream_surface` | `#FFF8E7` | Tray backgrounds, sticker album pages, wish bubbles |
| `night_slumber_tint` | `#2B2D5C` | Canvas modulate tint during `SLEEP` lamp-off state |

---

## 3. Viewport, Safe Zone & Proportions
- **Base Canvas:** `1920×1080` (`canvas_items` stretch, `expand` aspect).
- **4:3 iPad Expansion (`2048×1536` → `1920×1440` logical):**
  - Background `TextureRect` fills 100% of the expanded viewport (`EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_COVERED`) — **0 px letterbox bars**.
  - Interactive UI and trays anchor to the viewport edges with a `36 px` safe inset. There is **no**
    centred `SafeStage` container; composition is fixed by [ADR-008](specs/adr/ADR-008-edge-anchored-responsive-composition.md):
    **anchors are ratios of the canvas** (positions and the rig's height), **offsets are absolute pixels**
    (36 px insets, fixed hit-target sizes, the rig's feet-line offset) — insets and 120×120 px targets must
    not scale with the canvas. The rig scales the **painted** character to its box height, so the seen
    height is the box height; the box width follows the art aspect, so the tap surface is the character.
    `GeometryOracle` asserts the painted rect, the feet line and the insets.
- **Hero Scale (`QuiQuiRig`):**
  - In care rooms (`Casa`, `Cozinha`, `Banheiro`, `Closet`, `Jardim`, `Quarto`), QuiQui occupies **`55%–65%` of viewport height** (`~620 px` tall at rest on the 16:9 canvas, `~827 px` on `1920×1440`, `~882 px` on `2048×1536`; the **ratio** is the contract on every aspect), centered horizontally with visible feet anchored at `78%` of viewport height. **Measured on the opaque character**, not on the art frame or the `Control` box: the shipped art carries a ~8 % transparent margin.
- **Hit Targets:**
  - All buttons, food items, bath tools, clothes, and furniture pieces MUST have a minimum bounding box of **`120×120 px`** (preferred `148×148 px`) with `>=24 px` spacing between neighbors.

---

## 4. "Personagem com Vida" (Living Character Motion Specs)
1. **Continuous Idle Breathing:** Sinusoidal `scale` oscillation around foot pivot (`scale.x = 1.0 - 0.018 * sin(t * 2.2)`, `scale.y = 1.0 + 0.022 * sin(t * 2.2)`).
2. **Natural Blinking:** Every `2.8–5.2 s` (randomized), swap facial expression overlay to `quiqui_pisca.png` for `130 ms` when in neutral idle.
3. **Contextual Anticipation:**
   - Dragging food within `220 px` of `mouth_zone` → immediate expression change to `quiqui_boca_aberta.png`.
   - Entering `BathScene` (`RINSE` stage) → `quiqui_molhada.png`; completing `DRY` → `quiqui_brilhando.png` + `brilho.png` burst.
   - Idle `>8.0 s` without touch in a care room → `quiqui_carente.png` + subtle wish-bubble pulse.
4. **Jelly Squash & Stretch:**
   - Every tap on `TapButton` or `QuiQuiRig` plays a 3-keyframe spring (`scale (1.14, 0.88)` over `70 ms` → `(0.94, 1.07)` over `90 ms` → `(1.0, 1.0)` over `110 ms`, `TRANS_BACK`).
5. **Layered Outfit + Expression Invariant:**
   - Wearing any outfit (`macacao_verde`, `vestido_florido`, `vestido_vermelho`, `pijama`) or accessory (`coroa`, `laco_roxo`, `chapeu_amarelo`, `tiara_flores`, `oculos_coracao`, `cachecol_azul`) MUST composite cleanly with all 14 facial expressions without hiding the face reaction.
