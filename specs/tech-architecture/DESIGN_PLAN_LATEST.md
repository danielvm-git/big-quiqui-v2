# Visual & Scene Design Architecture (`DESIGN_PLAN_LATEST.md`)

<!-- story: e01s01 -->

See [`DESIGN.md`](file:///Users/danielvm/Developer/big-quiqui-v2/DESIGN.md) for color tokens, typography/zero-text rules, and motion curves.

## Scene Inventory & Visual Mapping (17 Scenes Across Epics `e01`–`e10`)
| Epic | Scene File | Background Asset | Primary Interactive Elements |
|---|---|---|---|
| `e01` | `res://scenes/titulo.tscn` | `bg_title.jpg` | `QuiQuiRig` (`acenando`), `play_button.png` |
| `e02` | `res://scenes/casa.tscn` | `bg_home.jpg` | `QuiQuiRig` + `wish_bubble.png`, 5 room doors, `CareDotsBar`, `CoinTicketHud`, Vila door |
| `e03` | `res://scenes/cozinha.tscn` | `bg_kitchen.jpg` | `QuiQuiRig` (`boca_aberta`/`mastigando`/`prazer`), `tray.png` + 10 foods, `crumbs.png`, `heart.png` |
| `e04` | `res://scenes/banheiro.tscn` | `bg_bathroom.jpg` | `QuiQuiRig` (`molhada`/`brilhando`), `sponge.png`, `shampoo.png`, `soap.png`, `shower_head.png`, `towel.png`, `espuma_*`, `droplet.png`, `bubble.png` |
| `e05` | `res://scenes/closet.tscn` | `bg_bedroom.jpg` | `QuiQuiRig` (layered outfits + accessories), `vertical_panel.png`, 4 outfits + 6 accessories, `sparkle.png` |
| `e06` | `res://scenes/jardim.tscn` | `bg_playroom.jpg` | `QuiQuiRig` (`pulando`/`rindo`), `ball.png`, `plush.png`, `pinwheel.png` |
| `e07` | `res://scenes/quarto_sono.tscn`<br>`res://scenes/celebracao.tscn` | `bg_bedroom.jpg`<br>`bg_celebration.jpg` | lamp (`zzz.png` placeholder), blanket (`plush.png` placeholder), `quiqui_sleepy.png`, `zzz.png`<br>`confetti.png`, `coin.png` + `fortune_wheel.png` (reward reveal) |
| `e08` | `res://scenes/vila.tscn`<br>`res://scenes/roda.tscn` | `bg_village.jpg`<br>`bg_playroom.jpg` | 6 village POI buttons + `trash_bag.png` recycling<br>`fortune_wheel.png` + `ponteiro_roda.png` |
| `e09` | `res://scenes/mercado.tscn`<br>`res://scenes/casinha.tscn`<br>`res://scenes/festa.tscn` | `bg_market.jpg`<br>`bg_playhouse.jpg`<br>`bg_playhouse.jpg` | 12 furniture items (`moveis/*.png`)<br>Free furniture placement (`0..1` normalized)<br>QuiQui + `duck.png`, `bear.png`, `penguin.png` party |
| `e10` | `res://scenes/pato_danca.tscn`<br>`res://scenes/urso_puzzle.tscn`<br>`res://scenes/pinguim_jogo.tscn`<br>`res://scenes/album.tscn` | `bg_playroom.jpg`<br>`bg_puzzle.jpg`<br>`bg_playroom.jpg`<br>`bg_album.jpg` | `duck.png` dance rounds<br>`bear.png` jigsaw puzzle<br>`penguin.png` ball catch<br>`star.png` sticker slots |
