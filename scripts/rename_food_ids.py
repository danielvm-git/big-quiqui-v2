#!/usr/bin/env python3
# story: e12s01
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
FOODS = GAME / "resources/foods"

RENAMES = {
    "cenoura": "carrot",
    "macarrao_cenoura": "carrot_pasta",
    "molho_cenoura": "carrot_sauce",
    "cenoura_quiqui": "quiqui_carrot",
    "maca": "apple",
    "morango": "strawberry",
    "melancia": "watermelon",
    "uva": "grape",
}

ACCESSORY = {"oculos_coracao": "heart_glasses"}


def main() -> None:
    for old, new in RENAMES.items():
        src = FOODS / f"{old}.tres"
        if src.exists():
            text = src.read_text(encoding="utf-8")
            text = text.replace(f'id = "{old}"', f'id = "{new}"')
            dst = FOODS / f"{new}.tres"
            dst.write_text(text, encoding="utf-8")
            if old != new:
                src.unlink()
    for path in GAME.rglob("*"):
        if path.suffix not in {".gd", ".tscn", ".tres"}:
            continue
        if "addons" in str(path):
            continue
        text = path.read_text(encoding="utf-8")
        orig = text
        for old, new in {**RENAMES, **ACCESSORY}.items():
            text = text.replace(f'"{old}"', f'"{new}"')
            text = text.replace(f"/{old}.tres", f"/{new}.tres")
            text = text.replace(f"%s{old}" % "", f"%s{new}" % "")
        text = text.replace("oculos_heart.png", "heart_glasses.png")
        text = text.replace("molho_carrot.png", "carrot_sauce.png")
        text = text.replace("macarrao_carrot.png", "carrot_pasta.png")
        if text != orig:
            path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
