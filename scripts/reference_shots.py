#!/usr/bin/env python3
"""Fetch public iPad store screenshots for benchmark reference titles.

Why this exists: the observation pass in `specs/product/TUTOTOONS_REFERENCE.md`
measures composition (character ratio, HUD insets, rail width) on a canvas that
matches our target 4:3 iPad. Apple's public lookup API serves thumbnail URLs; the
size segment swaps to a 2048-wide variant, which is our canvas.

The pixels never enter git (see .gitignore: `reference/`); only the measured
numbers and the source URLs go into the doc.

Usage:
    python3 scripts/reference_shots.py list
    python3 scripts/reference_shots.py fetch            # all titles -> reference/<slug>/
    python3 scripts/reference_shots.py fetch fluvsies   # one title
    python3 scripts/reference_shots.py sheet fluvsies   # 2x2 contact sheet for triage
    python3 scripts/reference_shots.py grid fluvsies 3  # grid overlay on shot 3

Requires: Pillow. No extra deps, no credentials, no APK.
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "reference"
API = "https://itunes.apple.com/search"

# The five titles chosen for the care-loop benchmark (see the doc, "Sample").
TITLES: dict[str, dict[str, str]] = {
    "fluvsies": {"term": "fluvsies", "match": "Fluvsies - Cute Virtual Pets", "why": "care/collect at scale"},
    "smolsies": {"term": "smolsies", "match": "Smolsies", "why": "pet care + house customisation"},
    "kpopsies": {"term": "kpopsies", "match": "Kpopsies", "why": "hatch/collect/grow pacing"},
    "dopples": {"term": "dopples world", "match": "Dopples World", "why": "current-generation feel"},
    # Cleanup 5 is Android-only today; the iOS build of Cleanup 4 carries the same
    # task-loop cadence, and the doc records the substitution.
    "sbg-cleanup": {"term": "sweet baby girl cleanup", "match": "Cleanup 4", "why": "task-loop cadence"},
}

BIG_SUFFIX = "/2048x2732bb.jpg"


def _get(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "reference-shots/1"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def lookup(term: str) -> list[dict]:
    query = urllib.parse.urlencode({"term": term, "entity": "software", "country": "us", "limit": 8})
    return json.loads(_get(f"{API}?{query}").decode()).get("results", [])


def resolve(slug: str) -> dict:
    spec = TITLES[slug]
    for result in lookup(spec["term"]):
        if spec["match"].lower() in str(result.get("trackName", "")).lower():
            return result
    raise SystemExit(f"no app matching {spec['match']!r} for slug {slug!r}")


def upscale(url: str) -> str:
    """Swap the trailing `<W>x<H>bb.jpg` size segment for a 2048-wide variant."""
    head, _, _ = url.rpartition("/")
    return head + BIG_SUFFIX


def cmd_list() -> int:
    for slug, spec in TITLES.items():
        print(f"{slug:12s} {spec['term']:22s} {spec['why']}")
    return 0


def cmd_fetch(slugs: list[str]) -> int:
    for slug in slugs or list(TITLES):
        result = resolve(slug)
        target = OUT / slug
        target.mkdir(parents=True, exist_ok=True)
        urls = list(result.get("ipadScreenshotUrls") or []) or list(result.get("screenshotUrls") or [])
        meta = {
            "slug": slug,
            "track_name": result.get("trackName"),
            "bundle_id": result.get("bundleId"),
            "track_id": result.get("trackId"),
            "artist": result.get("artistName"),
            "version": result.get("version"),
            "released": result.get("currentVersionReleaseDate"),
            "rating": result.get("averageUserRating"),
            "rating_count": result.get("userRatingCount"),
            "genres": result.get("genres"),
            "source_urls": [upscale(url) for url in urls],
            "note": "marketing composites; not device captures",
        }
        (target / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")
        for index, url in enumerate(urls):
            path = target / f"shot_{index}.jpg"
            path.write_bytes(_get(upscale(url)))
            size = Image.open(path).size
            print(f"{slug} shot_{index} {size[0]}x{size[1]} {path.stat().st_size // 1024} KB")
    return 0


def _font(size: int = 22) -> ImageFont.ImageFont:
    for candidate in (
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ):
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def _label(image: Image.Image, text: str) -> None:
    draw = ImageDraw.Draw(image)
    font = _font(26)
    draw.rectangle([0, 0, draw.textlength(text, font=font) + 16, 34], fill=(0, 0, 0))
    draw.text((8, 4), text, fill=(255, 255, 255), font=font)


def cmd_sheet(slug: str, per_sheet: int = 4) -> int:
    """2x2 contact sheet: one image to triage eight frames."""
    source = sorted((OUT / slug).glob("shot_*.jpg"))
    if not source:
        raise SystemExit(f"run `fetch {slug}` first")
    for start in range(0, len(source), per_sheet):
        chunk = source[start : start + per_sheet]
        thumbs = []
        for path in chunk:
            image = Image.open(path).convert("RGB")
            image.thumbnail((720, 540))
            _label(image, path.stem)
            thumbs.append(image)
        rows = (len(thumbs) + 1) // 2
        width = max(t.width for t in thumbs) * 2
        height = max(t.height for t in thumbs) * rows
        sheet = Image.new("RGB", (width, height), (24, 24, 24))
        for index, thumb in enumerate(thumbs):
            sheet.paste(thumb, ((index % 2) * width // 2, (index // 2) * (height // rows)))
        out = OUT / slug / f"sheet_{start // per_sheet}.jpg"
        sheet.save(out, quality=88)
        print(out)
    return 0


def cmd_grid(slug: str, index: int) -> int:
    """Percent grid: read composition straight off the labelled lines."""
    path = OUT / slug / f"shot_{index}.jpg"
    image = Image.open(path).convert("RGB")
    width, height = image.size
    draw = ImageDraw.Draw(image)
    font = _font(20)
    for step in range(1, 10):
        y = int(height * step / 10)
        draw.line([(0, y), (width, y)], fill=(0, 255, 0), width=2)
        draw.text((6, y + 2), f"{step * 10}%", fill=(0, 255, 0), font=font)
    for step in range(1, 20):
        x = int(width * step / 20)
        colour = (255, 255, 0) if step % 5 else (255, 0, 255)
        draw.line([(x, 0), (x, height)], fill=colour, width=1)
    out = OUT / slug / f"grid_{index}.jpg"
    image.save(out, quality=92)
    print(f"{out}  {width}x{height}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    command, rest = argv[1], argv[2:]
    if command == "list":
        return cmd_list()
    if command == "fetch":
        return cmd_fetch(rest)
    if command == "sheet":
        return cmd_sheet(rest[0])
    if command == "grid":
        return cmd_grid(rest[0], int(rest[1]))
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
