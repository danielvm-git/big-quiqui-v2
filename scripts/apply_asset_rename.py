#!/usr/bin/env python3
# story: e12s01
"""Apply specs/product/ASSET_RENAME_MAP.md under game/assets and rewrite references."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
MAP = ROOT / "specs/product/ASSET_RENAME_MAP.md"
ASSETS = GAME / "assets"


def parse_map() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in MAP.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| art/") and not line.startswith("| audio/"):
            continue
        parts = [p.strip() for p in line.split("|") if p.strip()]
        if len(parts) != 2 or parts[0] == "Today (path under `game/assets/`)":
            continue
        rows.append((parts[0], parts[1]))
    return rows


def rename_assets(rows: list[tuple[str, str]]) -> None:
    for old_rel, new_rel in rows:
        old_path = ASSETS / old_rel
        new_path = ASSETS / new_rel
        if not old_path.exists():
            if new_path.exists():
                continue
            raise FileNotFoundError(old_path)
        new_path.parent.mkdir(parents=True, exist_ok=True)
        old_path.rename(new_path)
        imp = Path(str(old_path) + ".import")
        if imp.exists():
            imp.rename(Path(str(new_path) + ".import"))
        uid = Path(str(old_path) + ".uid")
        if uid.exists():
            uid.rename(Path(str(new_path) + ".uid"))


def replace_in_tree(rows: list[tuple[str, str]]) -> int:
    count = 0
    patterns: list[tuple[str, str]] = []
    for old_rel, new_rel in rows:
        old_token = f"assets/{old_rel}"
        new_token = f"assets/{new_rel}"
        patterns.append((old_token, new_token))
        old_parent = str(Path(old_rel).parent).replace("\\", "/")
        new_parent = str(Path(new_rel).parent).replace("\\", "/")
        if old_parent != new_parent:
            patterns.append((old_parent, new_parent))
    globs = ["**/*.gd", "**/*.tscn", "**/*.tres", "**/*.md"]
    targets: set[Path] = set()
    for g in globs:
        targets.update(GAME.glob(g))
        targets.update(ROOT.glob(f"specs/**/{g.split('/')[-1]}"))
    for path in sorted(targets):
        if "addons/" in str(path):
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in patterns:
            text = text.replace(old, new)
        if text != original:
            path.write_text(text, encoding="utf-8")
            count += 1
    return count


def main() -> int:
    rows = parse_map()
    if len(rows) != 135:
        print(f"expected 135 rows, got {len(rows)}", file=sys.stderr)
        return 1
    rename_assets(rows)
    # Remove empty Portuguese dirs
    for d in ["amigos", "moveis", "efeitos", "estilo"]:
        p = ASSETS / "art" / d
        if p.exists() and not any(p.iterdir()):
            p.rmdir()
    old_voice = ASSETS / "audio" / "voice"
    if old_voice.exists() and not any(old_voice.iterdir()):
        old_voice.rmdir()
    n = replace_in_tree(rows)
    print(f"renamed {len(rows)} assets; updated {n} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
