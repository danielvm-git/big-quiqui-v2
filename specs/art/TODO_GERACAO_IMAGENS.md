# Checklist de Geração de Imagens — Coelinha QuiQui (Repaginada Visual Premium)

**Data:** 2026-11-02 · **Escopo:** `specs/product/SCOPE_REPAGINADA_LATEST.yaml`  
**Decisão de arte:** O jogo inteiro adota o estilo infantil premium brilhante (cores de bala saturadas, 3D suave, olhos grandes expressivos, formas arredondadas e amigáveis). Homogeneidade total em personagens, cenários, itens e interface.

---

## 🛡️ Regra de Ouro (Propriedade Intelectual & Identidade)

- **Nunca** anexar prints de outros jogos no gerador.
- **Nunca** mencionar marcas comerciais ou personagens de terceiros nos prompts.
- Os prompts abaixo descrevem puramente a estética técnica e mantêm a QuiQui 100% autoral.

---

## 📋 Como Operar o Gerador (Passo a Passo)

1. **Uma conversa nova para cada lote**: No mesmo chat, o modelo preserva a coesão do estilo.
2. **Anexos de referência**: Anexe sempre as imagens indicadas (estilo e/ou layout do cenário) antes de enviar o primeiro prompt.
3. **Fluxo de envio**: Envie a mensagem de abertura do lote, aguarde `"ok"`, e envie **um prompt por mensagem**.
4. **Critérios de Aceite (Quality Gate)**:
   - [ ] Fundo **branco liso puro** (`#FFFFFF`), exceto nos cenários.
   - [ ] **Sem texto**, letras, assinaturas ou números.
   - [ ] Nada cortado nas bordas (respiro ao redor).
   - [ ] Consistência do personagem nos lotes da QuiQui (mesmo laço de bolinhas, mesmos olhos lilases).
5. **Correções**: Se o fundo não sair branco liso, comande: *"Keep everything, but make the background pure white"*. Se descaracterizar a personagem, abra um chat novo e reanexe a referência.
6. **Salvamento**: Salve com o **nome exato** na pasta indicada. O pipeline técnico do agente cuida do recorte alpha e redimensionamento.

---

## 🎨 Descrição Geral do Estilo

> **STYLE:** glossy high-quality cartoon like a premium mobile game for young kids. Soft 3D-looking shading with smooth gradients, gentle rim light and shiny highlights. Rounded, chunky, friendly shapes. Saturated candy colors: bubblegum pink, lilac, turquoise, mint, lemon yellow, sky blue. Clean edges, no sketchy lines, no paper texture, no watercolor.

Para personagens:
> chibi proportions with a big head and small body, huge sparkly eyes with large colored irises, several white shine highlights and long lashes, small cute nose, rosy blush on the cheeks, soft fluffy fur rendered smoothly.

---

## 🛑 Lote 0 — Âncora de Estilo (HOMOLOGADO)
> **Status:** ✅ **APROVADO PELA OLIVIA EM 2026-11-02**  
> **Destino:** `specs/art/style/` · **Branch:** `feat/art-lote-0-estilo`

- [x] **1. `quiqui_model.png`** (Vista frontal oficial — 1024×1024)
- [x] **2. `kitchen_model.jpg`** (Cenário oficial — 1200×896)
- [x] **3. `carrot_model.png`** (Item oficial com carinha — 1024×1024)

---

## 🐰 Lote 1 — QuiQui: Expressões e Roupas (18 Imagens)
> **Referência a anexar:** `specs/art/style/quiqui_model.png`  
> **Destino:** `specs/art/quiqui/` · **Branch:** `feat/art-lote-1-quiqui-expressoes`

**Mensagem de abertura:**
```text
The attached image is QuiQui, the main character of my game. I will ask for several images of her. In EVERY image keep exactly the same character and art style: same fur color, same pink polka-dot bow on her head, same eyes, same proportions, same size and position in the frame, full body, front view, centered. Pure white background, no ground, no shadow, no text. Square image with white space around her. Reply "ok" and wait.
```

- [x] **1. `quiqui_base.png`** — Pose neutra: `Same character, calm happy face, gentle smile, eyes open, paws relaxed in front of her belly.`
- [x] **2. `quiqui_wink.png`** — Piscar: `Exactly the same as the neutral image, only the eyes closed in a relaxed blink. Nothing else changes.`
- [x] **3. `quiqui_laughing.png`** — Acertou/carinho: `Laughing with joy: eyes closed in happy arcs, mouth wide open, extra blush, paws together near her chin.`
- [x] **4. `quiqui_mouth_open.png`** — Esperando comida: `Mouth wide open waiting to be fed, big excited eyes looking up, paws up near her mouth.`
- [x] **5. `quiqui_chewing.png`** — Comendo: `Chewing happily: round puffed cheeks, mouth closed in a little wavy line, eyes closed in delight.`
- [x] **6. `quiqui_pleased.png`** — Banho/carinho: `Eyes peacefully closed, soft content smile, head slightly tilted, ears relaxed.`
- [x] **7. `quiqui_grimace.png`** — Gesto errado (cômico): `Silly funny face: one eye squeezed shut, tongue out a little, ears in different directions. Playful, not sad.`
- [x] **8. `quiqui_surprised.png`** — Algo novo: `Surprised: eyes extra wide and sparkly, small round "o" mouth, ears straight up, paws open.`
- [x] **9. `quiqui_sleepy.png`** — Cansada: `Sleepy: eyes half closed, small yawn with a paw over her mouth, ears drooping a little.`
- [x] **10. `quiqui_needy.png`** — Pedindo cuidado: `Asking for care in a cute way: big shiny pleading eyes, ears slightly drooped, small pout, paws clasped. Cute, never crying.`
- [x] **11. `quiqui_waving.png`** — Tela inicial: `Waving hello with her right paw raised high, big happy smile.`
- [x] **12. `quiqui_jumping.png`** — Celebração: `Jumping with joy, both arms up, feet off the ground, big open smile, eyes closed in happy arcs. Same size so she fits the frame.`
- [x] **13. `quiqui_wet.png`** — Durante o banho: `Wet after a bath: fur flattened and damp with a few water drops, squinting eyes, funny surprised smile.`
- [x] **14. `quiqui_shining.png`** — Limpinha: `Extra fluffy and clean, glossy fur, a few tiny white sparkles around her, proud happy smile.`
- [x] **15. `quiqui_floral_dress.png`** — Roupa arrumar: `Same neutral pose, wearing a cute peach dress with tiny pastel flowers.`
- [x] **16. `quiqui_green_overalls.png`** — Roupa arrumar: `Same neutral pose, wearing mint-green overalls with a front pocket.`
- [x] **17. `quiqui_red_dress.png`** — Roupa arrumar: `Same neutral pose, wearing a cherry-red dress with a white collar.`
- [x] **18. `quiqui_pajamas.png`** — Roupa dormir: `Same neutral pose, wearing lilac pajamas with little stars.`

---

## 🏞️ Lote 2 — Cenários (12 Imagens)
> **Anexar sempre:** `specs/art/style/kitchen_model.jpg` (estilo) + cenário antigo indicado (layout de objetos).  
> **Destino:** `specs/art/backgrounds/` · **Branch:** `feat/art-lote-2-cenarios` · **Formato:** Horizontal 4:3 (exceto vila panorâmica). Centro livre.

**Mensagem de abertura:**
```text
I will ask for game backgrounds. Use exactly the art style of the first attached image (glossy candy-colored cartoon, soft gradients, rounded chunky furniture, bright and cheerful). When I attach a second image, use it only to know what objects the room has; do not copy its drawing style. Never draw characters, text or letters. Keep the center and bottom center of the picture mostly empty for a character to stand. Landscape 4:3 unless I say otherwise. Reply "ok" and wait.
```

- [x] **1. `bg_kitchen.jpg`** — *(Reutilizada `kitchen_model.jpg` aprovada no Lote 0)*
- [x] **2. `bg_bathroom.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_bathroom.jpg`)*:  
  `A cute cartoon bathroom: a big round pastel bathtub in the front center, turquoise and pink tiles, a round mirror, a shower head, soft bubbles floating.`
- [x] **3. `bg_bedroom.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_guarda_roupa.jpg`)*:  
  `A cute cartoon bedroom with a big open wardrobe full of colorful clothes on the left, a vanity mirror, a heart-shaped rug, starry wallpaper in lilac.`
- [x] **4. `bg_home.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_toca.jpg`)*:  
  `The cozy living room of a bunny house: a round front door, a soft sofa, a fireplace, a bookcase, a big window, garlands of small lights. No sign, no text.`
- [x] **5. `bg_playroom.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_playroom.jpg`)*:  
  `A sunny cartoon garden play area behind the bunny house: soft green grass, flowers, a little fence, a swing, blue sky with fluffy clouds.`
- [x] **6. `bg_village.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_village.jpg`)*:  
  `A cheerful cartoon bunny village seen from the front, very wide panoramic image (as wide as possible): a row of cute candy-colored houses with rounded roofs, a furniture shop, a carrot market, a plaza with a big colorful wheel, trees and flowers, a path along the bottom.`
- [x] **7. `bg_market.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_market.jpg`)*:  
  `Inside a cute furniture shop for bunnies: shelves with empty spots, pastel walls, a counter, balloons.`
- [x] **8. `bg_playhouse.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_playhouse.jpg`)*:  
  `An empty cute cartoon room ready to be decorated: pastel walls with a window, a wooden floor, nothing else, lots of empty space.`
- [x] **9. `bg_celebration.jpg`** *(Sem anexo extra)*:  
  `A festive party background: pastel balloons, garlands, confetti in the air, a soft radial burst of light in the center.`
- [x] **10. `bg_title.jpg`** *(Sem anexo extra)*:  
  `A dreamy sunny meadow at the edge of a bunny village: soft hills, flowers, small candy-colored houses far away, rainbow in the sky. Big empty grassy area in the center.`
- [x] **11. `bg_album.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_album.jpg`)*:  
  `A cozy cartoon wall covered with an empty scrapbook board in pastel colors, ribbons and little star stickers around the edges, empty center.`
- [x] **12. `bg_puzzle.jpg`** *(Anexar antigo: `game/assets/sprites/backgrounds/bg_puzzle.jpg`)*:  
  `A soft playroom background with a big empty pastel table in the center, toys on shelves around the edges.`

---

## ✨ Lote 3 — Efeitos de Cuidado (10 Imagens)
> **Referência a anexar:** `specs/art/style/carrot_model.png`  
> **Destino:** `specs/art/effects/` · **Branch:** `feat/art-lote-3-efeitos`

**Mensagem de abertura (padrão Lotes 3, 4, 5 e 6):**
```text
Use exactly the art style of the attached image: glossy candy-colored cartoon, soft 3D-looking shading, shiny highlights, rounded shapes. Pure white background, single object centered, no text, no letters, square image. Reply "ok" and wait.
```

- [x] **1. `foam_large.png`**: `A big fluffy cloud of soap foam made of many round white bubbles with pastel rainbow shine, like a foamy hairdo. No face.`
- [x] **2. `foam_medium.png`**: `A medium clump of soap foam, round white bubbles with rainbow shine. No face.`
- [x] **3. `foam_small.png`**: `A small blob of soap foam, three or four bubbles. No face.`
- [x] **4. `bubble.png`**: `A single see-through soap bubble with a pink and turquoise rainbow sheen and a white shine spot.`
- [x] **5. `droplet.png`**: `A single glossy light-blue water drop with a white shine. No face.`
- [x] **6. `crumbs.png`**: `A few small cute food crumbs scattered, light brown and orange bits.`
- [x] **7. `sparkle.png`**: `A four-pointed sparkle star, white and lemon yellow, soft glow.`
- [x] **8. `confetti.png`**: `Eight separate confetti pieces spread out, not touching: ribbons, circles and stars in pink, mint, lilac, yellow and sky blue.`
- [x] **9. `heart.png`**: `A glossy bubblegum-pink heart with a white shine. No face.`
- [x] **10. `zzz.png`**: `Three puffy lilac cloud shapes shaped like the letter z, getting smaller. Shapes only, no real text.`

---

## 🥕 Lote 4 — Comida, Banho, Brincar e Acessórios (29 Imagens)
> **Referência a anexar:** `specs/art/style/carrot_model.png`  
> **Destino:** `specs/art/items/` · **Branch:** `feat/art-lote-4-itens` · **Abertura:** a do Lote 3.

- [x] **1. `carrot.png`**: *(Reutilizada `carrot_model.png` aprovada no Lote 0)*
- [x] **2. `macarrao_carrot.png`**: `A small bowl of orange carrot pasta with a carrot slice on top, cute face on the bowl.`
- [x] **3. `molho_carrot.png`**: `A small pot of orange carrot sauce with a wooden spoon, cute face on the pot.`
- [x] **4. `quiqui_carrot.png`**: `A carrot shaped like a cute bunny head, with ears made of carrot leaves.`
- [x] **5. `apple.png`**: `A shiny red apple with a leaf, cute face.`
- [x] **6. `banana.png`**: `A yellow banana, cute face.`
- [x] **7. `strawberry.png`**: `A glossy strawberry, cute face.`
- [x] **8. `watermelon.png`**: `A slice of watermelon, cute face.`
- [x] **9. `grape.png`**: `A bunch of purple grapes, cute face.`
- [x] **10. `cupcake.png`**: `A pink frosted cupcake with sprinkles and a cherry, cute face.`
- [x] **11. `juice.png`**: `A glass of orange juice with a striped straw, cute face.`
- [x] **12. `sunflower_seeds.png`**: `A small pile of sunflower seeds in a tiny bowl, cute face on the bowl.`
- [x] **13. `bowl.png`**: `An empty round pastel pink food bowl seen slightly from above. No face.`
- [x] **14. `sponge.png`**: `A fluffy pastel yellow bath sponge with a few bubbles, cute face.`
- [x] **15. `soap.png`**: `A bar of pink soap with bubbles, cute face.`
- [x] **16. `shampoo.png`**: `A round lilac shampoo bottle with a pump, cute face, no label text.`
- [x] **17. `shower_head.png`**: `A turquoise handheld shower head spraying a few blue drops. No face.`
- [x] **18. `towel.png`**: `A folded fluffy lemon-yellow towel with white stripes. No face.`
- [x] **19. `duckling.png`**: `A yellow rubber duck bath toy, cute face.`
- [x] **20. `ball.png`**: `A bouncy ball with pastel rainbow stripes. No face.`
- [x] **21. `plush.png`**: `A small plush teddy bear, light brown, cute face.`
- [x] **22. `pinwheel.png`**: `A pinwheel with pink, mint and yellow blades on a stick. No face.`
- [x] **23. `hair_brush.png`**: `A small hairbrush with a lilac handle. No face.`
- [x] **24. `purple_bow.png`**: `A big puffy lilac hair bow. No face.`
- [x] **25. `yellow_hat.png`**: `A floppy lemon-yellow sun hat with a small flower. No face.`
- [x] **26. `blue_scarf.png`**: `A cozy sky-blue knitted scarf. No face.`
- [x] **27. `oculos_heart.png`**: `Heart-shaped pink sunglasses. No face.`
- [x] **28. `flower_tiara.png`**: `A flower crown with small pastel flowers. No face.`
- [x] **29. `crown.png`**: `A small golden princess crown with pink gems. No face.`

---

## 🔘 Lote 5 — Kit de Interface (11 Imagens)
> **Referência a anexar:** `specs/art/style/carrot_model.png`  
> **Destino:** `specs/art/ui/` · **Branch:** `feat/art-lote-5-ui`  
> **Abertura:** a do Lote 3, complementada com: *"These are buttons for a preschool game: glossy like candy, thick and easy to tap."*

- [x] **1. `home_button.png`**: `A round glossy lemon-yellow button with a simple white house icon.`
- [x] **2. `next_button.png`**: `A big round glossy lemon-yellow button with a thick white right arrow.`
- [x] **3. `back_button.png`**: `A round glossy lilac button with a thick white left arrow.`
- [x] **4. `play_button.png`**: `A large round glossy bubblegum-pink button with a big white play triangle.`
- [x] **5. `wish_bubble.png`**: `An empty white thought bubble with a soft lilac outline and two small bubbles trailing to the bottom left. Empty inside.`
- [x] **6. `coin.png`**: `A shiny gold coin with a small carrot embossed in the middle.`
- [x] **7. `star.png`**: `A puffy glossy gold star. No face.`
- [x] **8. `tray.png`**: `A long horizontal rounded tray panel in glossy mint with a white inner border, empty. Wide rectangle.`
- [x] **9. `vertical_panel.png`**: `A tall vertical rounded panel in glossy lilac with a white inner border, empty.`
- [x] **10. `progress_dot.png`**: `A small round glossy lemon-yellow dot.`
- [x] **11. `progress_dot_empty.png`**: `A small round light-gray dot with a soft white shine.`

---

## 🛋️ Lote 6 — Móveis (Mercado e Casinha) (12 Imagens)
> **Referência a anexar:** `specs/art/style/carrot_model.png`  
> **Destino:** `specs/art/furniture/` · **Branch:** `feat/art-lote-6-moveis`  
> **Abertura:** a do Lote 3, complementada com: *"Furniture pieces, front view, no faces."*

- [x] **1. `bed.png`**: `A cute single bed with a pink heart headboard and a fluffy blanket.`
- [x] **2. `bunk_bed.png`**: `A bunk bed in mint and pink with a little ladder.`
- [x] **3. `table.png`**: `A round pastel table.`
- [x] **4. `chair.png`**: `A small rounded chair in lilac.`
- [x] **5. `wardrobe.png`**: `A tall wardrobe with two round-top doors in turquoise.`
- [x] **6. `sofa.png`**: `A soft rounded sofa in bubblegum pink.`
- [x] **7. `lamp.png`**: `A table lamp with a scalloped pastel yellow shade.`
- [x] **8. `rug.png`**: `A round fluffy rug in rainbow pastel rings, seen from above at an angle.`
- [x] **9. `plant_pot.png`**: `A potted plant in a pink pot.`
- [x] **10. `bookshelf.png`**: `A small bookshelf with colorful books (no letters on the books).`
- [x] **11. `ladder.png`**: `A short cute staircase with rounded steps in pastel colors.`
- [x] **12. `door.png`**: `A round-top cartoon door in lemon yellow with a heart window.`

---

## 🐾 Lote 7 — Amigos da Vila (Planejado para Épico e20)
Os animais da vila serão remodelados após a estabilização do caminho principal.

---

## 📊 Progresso Geral

| Lote | Descrição | Total | Concluídos | Status |
|:---|:---|:---:|:---:|:---:|
| **Lote 0** | Âncora de Estilo | 3 | 3 | **100% (Aprovado Olivia)** |
| **Lote 1** | QuiQui: Expressões e Roupas | 18 | 18 | **100% Concluído** |
| **Lote 2** | Cenários | 12 | 12 | **100% Concluído** |
| **Lote 3** | Efeitos de Cuidado | 10 | 10 | **100% Concluído** |
| **Lote 4** | Comida, Banho, Itens | 29 | 29 | **100% Concluído** |
| **Lote 5** | Interface (UI) | 11 | 11 | **100% Concluído** |
| **Lote 6** | Móveis | 12 | 12 | **100% Concluído** |
| **Total** | | **95** | **95** | **100% Concluído** |
