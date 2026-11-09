#!/usr/bin/env python3
# story: e12s01
from pathlib import Path

ROOT = Path("/Users/danielvm/Developer/big-quiqui-v2-e12")
MAP = {
    "pisca": "wink",
    "boca_aberta": "mouth_open",
    "carente": "needy",
    "rindo": "laughing",
    "mastigando": "chewing",
    "sono": "sleepy",
    "brilhando": "shining",
    "molhada": "wet",
    "careta": "grimace",
    "pulando": "jumping",
    "prazer": "pleased",
    "surpresa": "surprised",
    "macacao_verde": "green_overalls",
    "vestido_florido": "floral_dress",
    "vestido_vermelho": "red_dress",
    "pijama": "pajamas",
    "acenando": "waving",
}

for path in ROOT.rglob("*"):
    if path.suffix not in {".gd", ".tscn", ".tres"}:
        continue
    if "addons" in str(path):
        continue
    text = path.read_text(encoding="utf-8")
    orig = text
    for old, new in MAP.items():
        text = text.replace(f'"{old}"', f'"{new}"')
        text = text.replace(f"'{old}'", f"'{new}'")
    if text != orig:
        path.write_text(text, encoding="utf-8")
