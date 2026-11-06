# Visual & Scene Design Architecture (`DESIGN_PLAN_LATEST.md`)

<!-- story: e01s01 -->

See [`DESIGN.md`](file:///Users/danielvm/Developer/big-quiqui-v2/DESIGN.md) for color tokens, typography/zero-text rules, and motion curves.

## Scene Inventory & Visual Mapping (17 Scenes Across Epics `e01`–`e10`)
| Epic | Scene File | Background Asset | Primary Interactive Elements |
|---|---|---|---|
| `e01` | `res://scenes/titulo.tscn` | `bg_titulo.jpg` | `QuiQuiRig` (`acenando`), `botao_play.png` |
| `e02` | `res://scenes/casa.tscn` | `bg_sala.jpg` | `QuiQuiRig` + `balao_desejo.png`, 5 room doors, `CareDotsBar`, `CoinTicketHud`, Vila door |
| `e03` | `res://scenes/cozinha.tscn` | `bg_cozinha.jpg` | `QuiQuiRig` (`boca_aberta`/`mastigando`/`prazer`), `bandeja.png` + 10 foods, `farelos.png`, `coracao.png` |
| `e04` | `res://scenes/banheiro.tscn` | `bg_banheiro.jpg` | `QuiQuiRig` (`molhada`/`brilhando`), `esponja.png`, `shampoo.png`, `sabonete.png`, `chuveirinho.png`, `toalha.png`, `espuma_*`, `gota.png`, `bolha.png` |
| `e05` | `res://scenes/closet.tscn` | `bg_quarto.jpg` | `QuiQuiRig` (layered outfits + accessories), `painel_vertical.png`, 4 outfits + 6 accessories, `brilho.png` |
| `e06` | `res://scenes/jardim.tscn` | `bg_jardim.jpg` | `QuiQuiRig` (`pulando`/`rindo`), `bola.png`, `pelucia.png`, `cata_vento.png` |
| `e07` | `res://scenes/quarto_sono.tscn`<br>`res://scenes/celebracao.tscn` | `bg_quarto.jpg`<br>`bg_celebracao.jpg` | lamp (`zzz.png` placeholder), blanket (`pelucia.png` placeholder), `quiqui_sono.png`, `zzz.png`<br>`confete.png`, `moedinha.png` + `roda_fortuna.png` (reward reveal) |
| `e08` | `res://scenes/vila.tscn`<br>`res://scenes/roda.tscn` | `bg_vila.jpg`<br>`bg_jardim.jpg` | 6 village POI buttons + `saquinho_lixo.png` recycling<br>`roda_fortuna.png` + `ponteiro_roda.png` |
| `e09` | `res://scenes/mercado.tscn`<br>`res://scenes/casinha.tscn`<br>`res://scenes/festa.tscn` | `bg_mercado.jpg`<br>`bg_casinha.jpg`<br>`bg_casinha.jpg` | 12 furniture items (`moveis/*.png`)<br>Free furniture placement (`0..1` normalized)<br>QuiQui + `pato.png`, `urso.png`, `pinguim.png` party |
| `e10` | `res://scenes/pato_danca.tscn`<br>`res://scenes/urso_puzzle.tscn`<br>`res://scenes/pinguim_jogo.tscn`<br>`res://scenes/album.tscn` | `bg_jardim.jpg`<br>`bg_puzzle.jpg`<br>`bg_jardim.jpg`<br>`bg_album.jpg` | `pato.png` dance rounds<br>`urso.png` jigsaw puzzle<br>`pinguim.png` ball catch<br>`estrela.png` sticker slots |
