#!/usr/bin/env python3
# story: e12s01
from pathlib import Path

ROOT = Path("/Users/danielvm/Developer/big-quiqui-v2-e12")
MAP = {
    "applecao_verde": "green_overalls",
    "macacao_verde": "green_overalls",
    "vestido_florido": "floral_dress",
    "vestido_vermelho": "red_dress",
    "pijama": "pajamas",
    "tiara_flores": "flower_tiara",
    "coroa": "crown",
    "chapeu_amarelo": "yellow_hat",
    "cachecol_azul": "blue_scarf",
    "laco_roxo": "purple_bow",
    "bola": "ball",
    "cenoura": "carrot",
}

for path in ROOT.rglob("*"):
    if path.suffix not in {".gd", ".tscn", ".tres", ".yaml", ".md"}:
        continue
    if "addons" in str(path) or "archive/" in str(path):
        continue
    text = path.read_text(encoding="utf-8")
    orig = text
    for old, new in MAP.items():
        text = text.replace(f'"{old}"', f'"{new}"')
        text = text.replace(f"'{old}'", f"'{new}'")
    if text != orig:
        path.write_text(text, encoding="utf-8")
