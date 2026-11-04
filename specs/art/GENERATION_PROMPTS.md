# Prompts de Geração — Assets Faltantes (e10s03)

**Razão de existir:** decisão 2026-07-01 — assets faltantes são gerados por IA no pipeline de imagens já usado para `specs/art/`. O dev roda os prompts; o agente integra os resultados. Sem estes assets, e10s03 fica parcial (lixo com placeholder Kenney, corações no-op, 6 outfits sem ícone).

**Dois estilos coexistem de propósito** (ambos já estabelecidos em specs/art/):
- **Personagens** → estilo `animais/`: lápis de cor storybook, contorno suave, textura de crayon, fundo branco.
- **Itens/ícones interativos** → estilo `items/`: kawaii de contorno grosso escuro, cores pastel chapadas, carinha opcional — silhueta forte que lê bem a 80–120 px.

**Parâmetros comuns a todos:** fundo branco puro (recorte fácil), objeto único centralizado, sem texto, quadrado 1024×1024. Salvar em `specs/art/<categoria>/` com o nome indicado.

## Prefixo comum (itens)

> kawaii sticker style, thick dark outline, flat pastel colors, cute face optional, single object centered, pure white background, no text, children's game icon —

## 1. Lixos ×6 (vila, e08s07) → `specs/art/lixos/`

| Arquivo | Prompt (após o prefixo comum) |
|---|---|
| lixo_banana.jpg | a cartoon banana peel, soft yellow, slightly droopy and silly |
| lixo_garrafa.jpg | an empty plastic bottle, light blue, small dent, recyclable look |
| lixo_papel.jpg | a crumpled paper ball, off-white with soft creases |
| lixo_lata.jpg | an empty soda can, pastel pink, pull tab up, tiny dent |
| lixo_maca.jpg | an apple core, pale green, cute bite marks |
| lixo_saquinho.jpg | a small crumpled paper bag, kraft brown |

## 2. Coração de partícula → `specs/art/items/heart.jpg`

> kawaii sticker style, thick dark outline, glossy pink heart with soft highlight, single heart centered, pure white background, no text — simple enough to read at 32px as a particle

## 3. Ícones de outfit ×6 (e01 arrumar) → `specs/art/outfits/`

| Arquivo | Prompt (após o prefixo comum) |
|---|---|
| outfit_cachecol_azul.jpg | a cozy knitted scarf, sky blue with soft fringe |
| outfit_chapeu_amarelo.jpg | a floppy sun hat, butter yellow with tiny flower |
| outfit_laco_roxo.jpg | a hair bow, soft purple, slightly oversized and puffy |
| outfit_macacao_verde.jpg | child-size overalls, sage green with front pocket |
| outfit_vestido_florido.jpg | a little dress, peach with tiny pastel flowers |
| outfit_bow_azul.jpg | a small ribbon bow tie, light blue |

## 4. Amigos sem retrato painterly ×2 → `specs/art/animais/`

Estilo `animais/` (NÃO usar o prefixo kawaii): soft colored-pencil storybook illustration, gentle outlines, crayon texture, cute rounded animal standing, big friendly eyes, pure white background, no text.

| Arquivo | Prompt (no estilo animais/) |
|---|---|
| pato.jpg | a cheerful little duck, soft yellow feathers, tiny orange beak |
| pinguim.jpg | a cozy little penguin, slate blue and cream, tiny red bow tie |

Depois de gerar: o agente troca `duck.tres`/`penguin.tres` para os novos retratos (mesmo drop-in do urso em e10s04).

## 5. Mobília ×5 (casinha/mercado/puzzle) → `specs/art/moveis/`

Descoberto no BUG-2026-07-01T200000: os PNGs de mobília do jogo são quadrados de cor chapada
(fallback de quota do e02s04). Estilo `items/` (prefixo kawaii comum). As silhuetas NÃO precisam
ser geradas — o jogo agora deriva escurecendo a própria arte.

| Arquivo | Prompt (após o prefixo comum) |
|---|---|
| movel_mesa.jpg | a cozy round wooden table, warm honey wood, tiny flower vase on top |
| movel_armario.jpg | a cute wardrobe closet, sage green with rounded doors and heart handle |
| movel_cadeira.jpg | a small cushioned chair, peach seat, rounded wooden legs |
| movel_vaso.jpg | a flower pot with a happy daisy, terracotta with tiny face |
| movel_abajur.jpg | a bedside lamp, butter yellow shade with soft glow dots |

## 6. POIs da Vila ×4 → `specs/art/pois/`

Prédios/objetos clicáveis da vila — hoje são retângulos de cor. Estilo do CENÁRIO (não kawaii):
soft storybook illustration matching a pastel village scene, gentle outlines, no text on signs,
single building centered, pure white background.

| Arquivo | Prompt |
|---|---|
| poi_lojinha.jpg | a tiny village kiosk shop with striped awning, pastel pink and cream |
| poi_roda.jpg | a small carnival prize wheel on a wooden stand, pastel segments, star pointer |
| poi_mercado.jpg | a small furniture market stall with wooden shelves showing tiny furniture |
| poi_casinha.jpg | a cozy bunny cottage with round door and heart window, cream and rose |

## 7. Já resolvidos com arte existente (NÃO gerar)

- **Esponja** → `specs/art/items/item_esponja_1782876633948.jpg` já existe; e10s03 integra e cria `game/data/items/bath/esponja.tres`.
- **Cenoura, roupinha, cama, sofá** → já em `specs/art/items/`.
- **18 amigos painterly** → já em `specs/art/animais/` (e10s04 integra).

## Depois de gerar

1. Salvar os JPG nos caminhos acima (commit em specs/art/).
2. Avisar o agente: e10s03 converte para PNG com alpha, redimensiona, cria/atualiza `.tres` e inverte os guard tests (`test_mechanics.gd:151` esponja, `:283` corações).

> **CONCLUÍDO 2026-07-02:** seções 5 e 6 integradas na branch `fix/bug-arte-poi-moveis`
> (BUG-2026-07-01T200000 ciclos 3-4, pipeline `convert_bug_art.gd`). As demais seções já
> haviam sido integradas por e10s03/e10s04.

→ verify: `ls specs/art/lixos/*.jpg specs/art/outfits/*.jpg specs/art/items/heart.jpg 2>/dev/null | wc -l` (esperado: 13 + 2 amigos)
