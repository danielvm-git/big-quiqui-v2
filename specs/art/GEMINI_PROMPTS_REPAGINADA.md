# Prompts para o Gemini — Repaginada (visual estilo jogo infantil premium)

**Data:** 2026-11-02 · **Escopo:** `specs/product/SCOPE_REPAGINADA_LATEST.yaml`
**Decisão de arte (2026-11-02):** o jogo inteiro troca o traço aquarela/livro infantil pelo visual que a Olivia gosta nos jogos da TutoTOONS: brilhante, cores de bala, olhos enormes. **Tudo** é refeito no estilo novo (personagem, cenários, itens, interface), porque misturar estilos é justamente o que deixa o jogo "não homogêneo".
**Quem gera:** o usuário, no Gemini. **Quem integra:** o agente (recorte de fundo, nomes, importação, captura de verificação).

## Regra de ouro (não pular)

Nós pegamos as **características** do visual (brilho, proporções, cores), nunca os personagens nem a marca de outra empresa. Por isso:

- **Não** anexe prints dos jogos da TutoTOONS no Gemini.
- **Não** escreva "TutoTOONS", "Floof", "Fluvsies" etc. nos prompts.
- Os prompts abaixo já descrevem o estilo com palavras. Isso basta e mantém a QuiQui 100% nossa.

---

## Como usar o Gemini (passo a passo)

1. Abra **gemini.google.com** (ou o app). Use **uma conversa nova para cada lote**: no mesmo chat ele mantém o estilo mais parecido.
2. Quando o lote pedir, **anexe a imagem de referência** (📎 → enviar arquivo).
3. Cole a **mensagem de abertura** do lote e depois **um prompt por mensagem**.
4. Confira cada imagem:
   - fundo **branco liso** (exceto nos cenários)?
   - **sem texto** nem letras?
   - nada cortado nas bordas?
   - mesmo estilo e, nos lotes da QuiQui, a mesma QuiQui?
5. Se algo saiu errado, corrija no mesmo chat com uma frase curta: *"Keep everything, but make the background pure white"*.
   Se o Gemini "perder" o personagem, abra um chat novo e anexe de novo a referência.
6. Baixe e salve com o **nome exato** da tabela, na pasta indicada. Não precisa recortar nem redimensionar.
7. Terminou um lote? Me avise. Eu integro e te mostro capturas das telas para aprovar.

---

## Descrição do estilo (já vai dentro dos prompts)

> **STYLE:** glossy high-quality cartoon like a premium mobile game for young kids. Soft 3D-looking shading with smooth gradients, gentle rim light and shiny highlights. Rounded, chunky, friendly shapes. Saturated candy colors: bubblegum pink, lilac, turquoise, mint, lemon yellow, sky blue. Clean edges, no sketchy lines, no paper texture, no watercolor.

Para personagens, mais isto:

> chibi proportions with a big head and small body, huge sparkly eyes with large colored irises, several white shine highlights and long lashes, small cute nose, rosy blush on the cheeks, soft fluffy fur rendered smoothly.

---

## Lote 0 — Âncora de estilo (FAZER PRIMEIRO, mostrar para a Olivia)

**Por quê:** estas três imagens viram o "padrão oficial". Todos os outros lotes anexam elas como referência. Se a Olivia não gostar de alguma coisa aqui (cor do laço, olhos, cores), é aqui que muda, antes de gerar as outras 80.

**Anexar:** `game/assets/sprites/characters/quiqui/quiqui_idle.png` (só para o Gemini saber quem é a QuiQui; o traço vai mudar)
**Salvar em:** `specs/art/style/`

**Mensagem de abertura:**

> I'm making a game for preschool kids. The attached image is my character QuiQui, a white bunny girl, but I want to completely redraw her in a new art style. STYLE: glossy high-quality cartoon like a premium mobile game for young kids. Soft 3D-looking shading with smooth gradients, gentle rim light and shiny highlights. Rounded, chunky, friendly shapes. Saturated candy colors: bubblegum pink, lilac, turquoise, mint, lemon yellow, sky blue. Clean edges, no sketchy lines, no paper texture, no watercolor. Reply "ok" and wait for my requests.

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `quiqui_model.png` | Redraw QuiQui in this style as a baby bunny girl: fluffy snow-white fur, long ears with bubblegum-pink insides, a big pink bow with white polka dots on top of her head between the ears, chibi proportions with a big head and small body, huge sparkly lilac eyes with several white shine highlights and long lashes, tiny pink nose, rosy blush, small fluffy tail. Full body, standing, front view, happy gentle smile, paws relaxed in front of her belly. Pure white background, no ground, no shadow, no text. Square image, white space around her so nothing is cut. |
| 2 | `kitchen_model.jpg` | In the same style, a cozy cartoon kitchen for a bunny: rounded pastel pink and mint cabinets, a cute fridge, a round window with sunlight, a small table in the front. Bright, cheerful and uncluttered; leave the center and bottom center mostly empty for a character to stand. No characters, no text, no letters. Landscape 4:3. |
| 3 | `carrot_model.png` | In the same style, a single glossy carrot with a leafy green top and a cute small happy face. Pure white background, centered, no text. Square image. |

**Pare aqui.** Mostre as três para a Olivia. Ajuste até ela gostar. Só depois siga.

---

## Lote 1 — QuiQui: expressões e roupas (PRIORIDADE MÁXIMA)

**Anexar:** `specs/art/style/quiqui_model.png` (a aprovada no Lote 0)
**Salvar em:** `specs/art/quiqui/`

**Mensagem de abertura:**

> The attached image is QuiQui, the main character of my game. I will ask for several images of her. In EVERY image keep exactly the same character and art style: same fur color, same pink polka-dot bow on her head, same eyes, same proportions, same size and position in the frame, full body, front view, centered. Pure white background, no ground, no shadow, no text. Square image with white space around her. Reply "ok" and wait.

| # | Arquivo | Uso no jogo | Prompt |
|---|---|---|---|
| 1 | `quiqui_base.png` | pose neutra | Same character, calm happy face, gentle smile, eyes open, paws relaxed in front of her belly. |
| 2 | `quiqui_wink.png` | piscar | Exactly the same as the neutral image, only the eyes closed in a relaxed blink. Nothing else changes. |
| 3 | `quiqui_laughing.png` | acertou, carinho | Laughing with joy: eyes closed in happy arcs, mouth wide open, extra blush, paws together near her chin. |
| 4 | `quiqui_mouth_open.png` | esperando comida | Mouth wide open waiting to be fed, big excited eyes looking up, paws up near her mouth. |
| 5 | `quiqui_chewing.png` | comendo | Chewing happily: round puffed cheeks, mouth closed in a little wavy line, eyes closed in delight. |
| 6 | `quiqui_pleased.png` | banho, carinho | Eyes peacefully closed, soft content smile, head slightly tilted, ears relaxed. |
| 7 | `quiqui_grimace.png` | gesto errado (cômico) | Silly funny face: one eye squeezed shut, tongue out a little, ears in different directions. Playful, not sad. |
| 8 | `quiqui_surprised.png` | algo novo | Surprised: eyes extra wide and sparkly, small round "o" mouth, ears straight up, paws open. |
| 9 | `quiqui_sleepy.png` | cansada | Sleepy: eyes half closed, small yawn with a paw over her mouth, ears drooping a little. |
| 10 | `quiqui_needy.png` | pedindo cuidado | Asking for care in a cute way: big shiny pleading eyes, ears slightly drooped, small pout, paws clasped. Cute, never crying. |
| 11 | `quiqui_waving.png` | tela inicial | Waving hello with her right paw raised high, big happy smile. |
| 12 | `quiqui_jumping.png` | celebração | Jumping with joy, both arms up, feet off the ground, big open smile, eyes closed in happy arcs. Same size so she fits the frame. |
| 13 | `quiqui_wet.png` | durante o banho | Wet after a bath: fur flattened and damp with a few water drops, squinting eyes, funny surprised smile. |
| 14 | `quiqui_shining.png` | limpinha | Extra fluffy and clean, glossy fur, a few tiny white sparkles around her, proud happy smile. |
| 15 | `quiqui_floral_dress.png` | arrumar | Same neutral pose, wearing a cute peach dress with tiny pastel flowers. |
| 16 | `quiqui_green_overalls.png` | arrumar | Same neutral pose, wearing mint-green overalls with a front pocket. |
| 17 | `quiqui_red_dress.png` | arrumar | Same neutral pose, wearing a cherry-red dress with a white collar. |
| 18 | `quiqui_pajamas.png` | dormir | Same neutral pose, wearing lilac pajamas with little stars. |

---

## Lote 2 — Cenários (todos no estilo novo)

**Anexar em todo prompt:** `specs/art/style/kitchen_model.jpg` (referência de estilo) **+** o cenário antigo indicado (só para o Gemini copiar o que tem no cômodo).
**Salvar em:** `specs/art/backgrounds/`
**Formato:** horizontal **4:3**, exceto a vila. Deixe o centro livre para a QuiQui.

**Mensagem de abertura:**

> I will ask for game backgrounds. Use exactly the art style of the first attached image (glossy candy-colored cartoon, soft gradients, rounded chunky furniture, bright and cheerful). When I attach a second image, use it only to know what objects the room has; do not copy its drawing style. Never draw characters, text or letters. Keep the center and bottom center of the picture mostly empty for a character to stand. Landscape 4:3 unless I say otherwise. Reply "ok" and wait.

| # | Arquivo | Anexar (antigo) | Prompt |
|---|---|---|---|
| 1 | `bg_kitchen.jpg` | — | Use the approved kitchen exactly as it is (you can skip this one and I will reuse `kitchen_model.jpg`). |
| 2 | `bg_bathroom.jpg` | `game/assets/sprites/backgrounds/bg_bathroom.jpg` | A cute cartoon bathroom: a big round pastel bathtub in the front center, turquoise and pink tiles, a round mirror, a shower head, soft bubbles floating. |
| 3 | `bg_bedroom.jpg` | `game/assets/sprites/backgrounds/bg_guarda_roupa.jpg` | A cute cartoon bedroom with a big open wardrobe full of colorful clothes on the left, a vanity mirror, a heart-shaped rug, starry wallpaper in lilac. |
| 4 | `bg_home.jpg` | `game/assets/sprites/backgrounds/bg_toca.jpg` | The cozy living room of a bunny house: a round front door, a soft sofa, a fireplace, a bookcase, a big window, garlands of small lights. No sign, no text. |
| 5 | `bg_playroom.jpg` | `game/assets/sprites/backgrounds/bg_playroom.jpg` | A sunny cartoon garden play area behind the bunny house: soft green grass, flowers, a little fence, a swing, blue sky with fluffy clouds. |
| 6 | `bg_village.jpg` | `game/assets/sprites/backgrounds/bg_village.jpg` | A cheerful cartoon bunny village seen from the front, very wide panoramic image (as wide as possible): a row of cute candy-colored houses with rounded roofs, a furniture shop, a carrot market, a plaza with a big colorful wheel, trees and flowers, a path along the bottom. |
| 7 | `bg_market.jpg` | `game/assets/sprites/backgrounds/bg_market.jpg` | Inside a cute furniture shop for bunnies: shelves with empty spots, pastel walls, a counter, balloons. |
| 8 | `bg_playhouse.jpg` | `game/assets/sprites/backgrounds/bg_playhouse.jpg` | An empty cute cartoon room ready to be decorated: pastel walls with a window, a wooden floor, nothing else, lots of empty space. |
| 9 | `bg_celebration.jpg` | — | A festive party background: pastel balloons, garlands, confetti in the air, a soft radial burst of light in the center. |
| 10 | `bg_title.jpg` | — | A dreamy sunny meadow at the edge of a bunny village: soft hills, flowers, small candy-colored houses far away, rainbow in the sky. Big empty grassy area in the center. |
| 11 | `bg_album.jpg` | `game/assets/sprites/backgrounds/bg_album.jpg` | A cozy cartoon wall covered with an empty scrapbook board in pastel colors, ribbons and little star stickers around the edges, empty center. |
| 12 | `bg_puzzle.jpg` | `game/assets/sprites/backgrounds/bg_puzzle.jpg` | A soft playroom background with a big empty pastel table in the center, toys on shelves around the edges. |

---

## Lote 3 — Efeitos de cuidado

**Anexar:** `specs/art/style/carrot_model.png` · **Salvar em:** `specs/art/effects/`

**Mensagem de abertura (vale também para os lotes 4, 5 e 6):**

> Use exactly the art style of the attached image: glossy candy-colored cartoon, soft 3D-looking shading, shiny highlights, rounded shapes. Pure white background, single object centered, no text, no letters, square image. Reply "ok" and wait.

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `foam_large.png` | A big fluffy cloud of soap foam made of many round white bubbles with pastel rainbow shine, like a foamy hairdo. No face. |
| 2 | `foam_medium.png` | A medium clump of soap foam, round white bubbles with rainbow shine. No face. |
| 3 | `foam_small.png` | A small blob of soap foam, three or four bubbles. No face. |
| 4 | `bubble.png` | A single see-through soap bubble with a pink and turquoise rainbow sheen and a white shine spot. |
| 5 | `droplet.png` | A single glossy light-blue water drop with a white shine. No face. |
| 6 | `crumbs.png` | A few small cute food crumbs scattered, light brown and orange bits. |
| 7 | `sparkle.png` | A four-pointed sparkle star, white and lemon yellow, soft glow. |
| 8 | `confetti.png` | Eight separate confetti pieces spread out, not touching: ribbons, circles and stars in pink, mint, lilac, yellow and sky blue. |
| 9 | `heart.png` | A glossy bubblegum-pink heart with a white shine. No face. |
| 10 | `zzz.png` | Three puffy lilac cloud shapes shaped like the letter z, getting smaller. Shapes only, no real text. |

---

## Lote 4 — Comida, banho, brincar e acessórios

**Anexar:** `specs/art/style/carrot_model.png` · **Salvar em:** `specs/art/items/` · **Abertura:** a do Lote 3.

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `carrot.png` | (use a `carrot_model.png` aprovada) |
| 2 | `macarrao_carrot.png` | A small bowl of orange carrot pasta with a carrot slice on top, cute face on the bowl. |
| 3 | `molho_carrot.png` | A small pot of orange carrot sauce with a wooden spoon, cute face on the pot. |
| 4 | `quiqui_carrot.png` | A carrot shaped like a cute bunny head, with ears made of carrot leaves. |
| 5 | `apple.png` | A shiny red apple with a leaf, cute face. |
| 6 | `banana.png` | A yellow banana, cute face. |
| 7 | `strawberry.png` | A glossy strawberry, cute face. |
| 8 | `watermelon.png` | A slice of watermelon, cute face. |
| 9 | `grape.png` | A bunch of purple grapes, cute face. |
| 10 | `cupcake.png` | A pink frosted cupcake with sprinkles and a cherry, cute face. |
| 11 | `juice.png` | A glass of orange juice with a striped straw, cute face. |
| 12 | `sunflower_seeds.png` | A small pile of sunflower seeds in a tiny bowl, cute face on the bowl. |
| 13 | `bowl.png` | An empty round pastel pink food bowl seen slightly from above. No face. |
| 14 | `sponge.png` | A fluffy pastel yellow bath sponge with a few bubbles, cute face. |
| 15 | `soap.png` | A bar of pink soap with bubbles, cute face. |
| 16 | `shampoo.png` | A round lilac shampoo bottle with a pump, cute face, no label text. |
| 17 | `shower_head.png` | A turquoise handheld shower head spraying a few blue drops. No face. |
| 18 | `towel.png` | A folded fluffy lemon-yellow towel with white stripes. No face. |
| 19 | `duckling.png` | A yellow rubber duck bath toy, cute face. |
| 20 | `ball.png` | A bouncy ball with pastel rainbow stripes. No face. |
| 21 | `plush.png` | A small plush teddy bear, light brown, cute face. |
| 22 | `pinwheel.png` | A pinwheel with pink, mint and yellow blades on a stick. No face. |
| 23 | `hair_brush.png` | A small hairbrush with a lilac handle. No face. |
| 24 | `purple_bow.png` | A big puffy lilac hair bow. No face. |
| 25 | `yellow_hat.png` | A floppy lemon-yellow sun hat with a small flower. No face. |
| 26 | `blue_scarf.png` | A cozy sky-blue knitted scarf. No face. |
| 27 | `oculos_heart.png` | Heart-shaped pink sunglasses. No face. |
| 28 | `flower_tiara.png` | A flower crown with small pastel flowers. No face. |
| 29 | `crown.png` | A small golden princess crown with pink gems. No face. |

---

## Lote 5 — Kit de interface

**Anexar:** `specs/art/style/carrot_model.png` · **Salvar em:** `specs/art/ui/` · **Abertura:** a do Lote 3, mais: *"These are buttons for a preschool game: glossy like candy, thick and easy to tap."*

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `home_button.png` | A round glossy lemon-yellow button with a simple white house icon. |
| 2 | `next_button.png` | A big round glossy lemon-yellow button with a thick white right arrow. |
| 3 | `back_button.png` | A round glossy lilac button with a thick white left arrow. |
| 4 | `play_button.png` | A large round glossy bubblegum-pink button with a big white play triangle. |
| 5 | `wish_bubble.png` | An empty white thought bubble with a soft lilac outline and two small bubbles trailing to the bottom left. Empty inside. |
| 6 | `coin.png` | A shiny gold coin with a small carrot embossed in the middle. |
| 7 | `star.png` | A puffy glossy gold star. No face. |
| 8 | `tray.png` | A long horizontal rounded tray panel in glossy mint with a white inner border, empty. Wide rectangle. |
| 9 | `vertical_panel.png` | A tall vertical rounded panel in glossy lilac with a white inner border, empty. |
| 10 | `progress_dot.png` | A small round glossy lemon-yellow dot. |
| 11 | `progress_dot_empty.png` | A small round light-gray dot with a soft white shine. |

---

## Lote 6 — Móveis (mercado e casinha, pedido da Olivia)

**Anexar:** `specs/art/style/carrot_model.png` · **Salvar em:** `specs/art/furniture/` · **Abertura:** a do Lote 3, mais: *"Furniture pieces, front view, no faces."*

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `bed.png` | A cute single bed with a pink heart headboard and a fluffy blanket. |
| 2 | `bunk_bed.png` | A bunk bed in mint and pink with a little ladder. |
| 3 | `table.png` | A round pastel table. |
| 4 | `chair.png` | A small rounded chair in lilac. |
| 5 | `wardrobe.png` | A tall wardrobe with two round-top doors in turquoise. |
| 6 | `sofa.png` | A soft rounded sofa in bubblegum pink. |
| 7 | `lamp.png` | A table lamp with a scalloped pastel yellow shade. |
| 8 | `rug.png` | A round fluffy rug in rainbow pastel rings, seen from above at an angle. |
| 9 | `plant_pot.png` | A potted plant in a pink pot. |
| 10 | `bookshelf.png` | A small bookshelf with colorful books (no letters on the books). |
| 11 | `ladder.png` | A short cute staircase with rounded steps in pastel colors. |
| 12 | `door.png` | A round-top cartoon door in lemon yellow with a heart window. |

---

## Lote 7 — Amigos (e20s05)

**Anexar:** `specs/art/style/quiqui_model.png` · **Salvar em:** `specs/art/friends/`
**Script:** `scripts/run_lote_7.js` (mesma lógica dos lotes 4–6).

**Mensagem de abertura:**

> Use exactly the art style of the attached image: glossy candy-colored cartoon for a premium preschool game, soft 3D-looking shading, smooth gradients, gentle rim light and shiny highlights, rounded chunky friendly shapes. Characters have chibi proportions with a big head and small body, huge sparkly eyes with large colored irises and several white shine highlights, rosy blush, soft smooth fur or feathers. Pure white background, single character centered, full body, front view, no ground, no shadow, no text, no letters. Square image with white space around. Reply "ok" and wait.

| # | Arquivo | Prompt |
|---|---|---|
| 1 | `duck.png` | Same art style, a chibi baby duck friend for the bunny village: fluffy lemon-yellow duckling, rounded body, small orange beak and orange webbed feet, huge sparkly dark eyes with white highlights, rosy cheeks, tiny wings, happy gentle smile. Full body, standing, front view, centered. Pure white background, no ground, no shadow, no text. Square image with white space around. |
| 2 | `bear.png` | Same art style, a chibi baby bear friend for the bunny village: soft light-brown teddy-bear cub, round ears, cream muzzle and belly, huge sparkly dark eyes with white highlights, rosy cheeks, happy gentle smile, small paws. Full body, standing, front view, centered. Pure white background, no ground, no shadow, no text. Square image with white space around. |
| 3 | `penguin.png` | Same art style, a chibi baby penguin friend for the bunny village: rounded black-and-white body, orange beak and orange feet, huge sparkly dark eyes with white highlights, rosy cheeks, happy gentle smile, small flippers. Full body, standing, front view, centered. Pure white background, no ground, no shadow, no text. Square image with white space around. |

---

## Checklist

Atualizado em 2026-11-02, depois de conferir **o conteúdo de cada imagem** contra o nome (não só a contagem de arquivos).

- [x] Lote 0 — âncora (3/3) → **aprovada pela Olivia** · branch `feat/art-lote-0-estilo`
- [x] Lote 1 — QuiQui (18/18) · branch `feat/art-lote-1-quiqui-expressoes` · no jogo: 18/18 (PR #6)
- [x] Lote 2 — cenários (12/12) · branch `feat/art-lote-2-cenarios` · `bg_vila` é a panorâmica; ainda não ligados no jogo (e17/e18)
- [x] Lote 3 — efeitos (10/10) · branch `feat/art-lote-3-efeitos` · ⚠️ `espuma_media` é a mesma imagem da `espuma_grande` (no jogo, usar menor; regerar é opcional)
- [x] Lote 4 — itens (29/29) · branch `feat/art-lote-4-itens`
- [x] Lote 5 — interface (11/11) · branch `feat/art-lote-5-ui`
- [x] Lote 6 — móveis (12/12) · branch `feat/art-lote-6-moveis`
- [x] Lote 7 — amigos (3/3) · branch `feat/art-lote-7` · gerado 2026-11-04

**Total:** 95/95 imagens prontas e com o nome certo. A fonte certa é o checkout principal (`docs/art-generation-checklist`); as branches `feat/art-lote-1/2/3` ainda têm os nomes trocados dos Lotes 1–3.

**Atenção na geração:** até aqui, a partir do 10º item do Lote 1, cada arquivo foi salvo com a imagem do pedido anterior (nomes deslocados em uma posição). Os nomes foram corrigidos e conferidos por hash. Nos próximos lotes, **abra cada arquivo depois de salvar** e confira se o desenho é o do nome, antes de marcar como feito.

O Lote 0 destrava todos os outros. Os lotes 1 e 2 destravam o caminho principal (e16 e e18).
