#!/usr/bin/env python3
"""Deep pass over pulled TutoTOONS APK sets.

For each package: engine identity, Unity version, IL2CPP metadata digest
(via REA), Assembly-CSharp domain inventory, SDK surface, Play Asset Delivery
layout, and device-side manifest facts (via adb dumpsys).

Writes one compact digest per package to .rea/report/digest-<pkg>.json.
Reads nothing outside .rea/acq; writes nothing outside .rea/report + /tmp.
"""
import json
import os
import re
import subprocess
import sys
import zipfile

ADB = "/opt/homebrew/bin/adb"
REA = "/Users/danielvm/.nvm/versions/node/v24.22.2/bin/rea"
ROOT = "/Users/danielvm/Developer/big-quiqui-v2"
ACQ = f"{ROOT}/.rea/acq"
OUT = f"{ROOT}/.rea/report"
SERIAL = "R9XT700Z7JV"
ENV = {**os.environ, "PATH": f"/opt/homebrew/bin:/Users/danielvm/.nvm/versions/node/v24.22.2/bin:{os.environ['PATH']}",
       "REA_ADB_PATH": ADB}

ENGINE_SIGS = {
    "libil2cpp.so": "unity-il2cpp",
    "global-metadata.dat": "unity-il2cpp",
    "libmonobdwgc-2.0.so": "unity-mono",
    "libunity.so": "unity",
    "META-INF/AIR/": "adobe-air",
    "libcocos2dcpp.so": "cocos2dx",
    "libgodot_android.so": "godot",
    "libflutter.so": "flutter",
    "libhermes.so": "react-native",
    "libdefold.so": "defold",
}

SDK_SIGS = {
    b"Lcom/google/firebase/": "firebase",
    b"Lcom/google/android/gms/ads/": "admob",
    b"Lcom/unity3d/ads/": "unity-ads",
    b"Lcom/unity3d/services/": "unity-services",
    b"Lcom/unity/purchasing/": "unity-iap",
    b"Lcom/android/billingclient/": "play-billing",
    b"Lcom/facebook/ads/": "meta-audience",
    b"Lcom/facebook/appevents/": "meta-appevents",
    b"Lcom/applovin/": "applovin",
    b"Lcom/ironsource/": "ironsource",
    b"Lcom/bytedance/sdk/openadsdk/": "pangle",
    b"Lcom/vungle/": "vungle",
    b"Lcom/adjust/sdk/": "adjust",
    b"Lcom/appsflyer/": "appsflyer",
    b"Lio/sentry/": "sentry",
    b"Lcom/google/android/play/core/": "play-core",
    b"Lcom/google/android/play/assetpacks/": "play-asset-delivery",
    b"Landroidx/work/": "androidx-work",
    b"Lcom/google/firebase/crashlytics/": "crashlytics",
    b"Lpl/droidsonroids/gif/": "gif-drawable",
    b"Lcom/onesignal/": "onesignal",
    b"Lcom/singular/sdk/": "singular",
}

# Types whose method inventory is worth quoting in the report.
WATCH = [
    "LevelUpSystem", "CoinSystem", "StatusBar", "IAPController", "IAPShopController",
    "PopupGetCoins", "ToolLock", "LockObject", "MovableTool", "CategoryController",
    "DrawLayer", "EraseLayer", "Slicer2D", "Slice2D", "Polygon2D", "Vector2D", "Math2D",
    "Template20Draggable", "Template47Draggable", "Template46PlayCup",
    "Template48Food", "Template50Player", "Template44Layer",
    "ScriptedAnimation", "ScriptedAnimationController", "AnimationSettings",
    "ScriptedAnimationSlot", "IMovieClipImitator", "PhotoGallery", "ScrollView",
    "ParticlesController", "SpriteProgressBar", "API",
]

KEYWORD_RE = re.compile(
    r"(Wish|Need|Care|Mood|Hunger|Clean|Dress|Sleep|Reward|Coin|Gem|Ticket|Level|Exp"
    r"|Timer|Decay|Cooldown|Progress|Save|Load|Popup|Tutorial|Hint|Ghost|Hand|Drag"
    r"|Touch|Tap|Audio|Music|Sfx|Voice|Locale|Analytic|Remote|Config|Debug|Cheat"
    r"|Event|Shop|IAP|Ad|Spin|Scene|Room|Pack)", re.I)

LITERAL_RE = re.compile(r"^[A-Za-z0-9_.\- ]{3,44}$")
LIT_KEYWORD_RE = re.compile(
    r"(prefs|player|save|slot|timer|decay|wish|interval|level|coin|reward|hint|tutorial"
    r"|ghost|voice|mood|hunger|clean|dress|sleep|scene|room|pack|locale|pt-?BR|en-?US"
    r"|loading|progress|unlock|star)", re.I)


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, env=ENV, **kw)


def apk_entries(path):
    try:
        with zipfile.ZipFile(path) as z:
            return z.namelist()
    except Exception:
        return []


def unity_version(apk, names):
    target = next((n for n in names if n.endswith("libunity.so")), None)
    if not target:
        return None
    try:
        with zipfile.ZipFile(apk) as z:
            blob = z.read(target)
    except Exception:
        return None
    found = re.findall(rb"20\d\d\.\d+\.\d+[abfp]\d+", blob)
    if not found:
        return None
    from collections import Counter
    best = Counter(f.decode() for f in found).most_common(1)[0][0]
    return best


def dex_sdks(apk, names):
    hits, blob = set(), b""
    try:
        with zipfile.ZipFile(apk) as z:
            for n in names:
                if re.fullmatch(r"classes\d*\.dex", n):
                    blob += z.read(n)
    except Exception:
        return []
    for sig, name in SDK_SIGS.items():
        if sig in blob:
            hits.add(name)
    return sorted(hits)


def dumpsys(pkg):
    out = run([ADB, "shell", f"dumpsys package {pkg}"]).stdout
    info = {}
    for key, pat in (("versionName", r"versionName=(\S+)"),
                     ("versionCode", r"versionCode=(\d+)"),
                     ("targetSdk", r"targetSdk=(\d+)"),
                     ("minSdk", r"minSdk=(\d+)"),
                     ("installer", r"installerPackageName=(\S+)"),
                     ("firstInstall", r"firstInstallTime=(\S+ \S+)"),
                     ("lastUpdate", r"lastUpdateTime=(\S+ \S+)")):
        m = re.search(pat, out)
        info[key] = m.group(1) if m else None
    perms = sorted(set(re.findall(r"(android\.permission\.[A-Z_]+): granted=(true|false)", out)))
    info["permissions_granted"] = [p for p, g in perms if g == "true"]
    info["permissions_denied"] = [p for p, g in perms if g == "false"]
    return info


def il2cpp_digest(pkg, base_apk):
    meta = f"/tmp/meta-{pkg}.dat"
    try:
        with zipfile.ZipFile(base_apk) as z:
            cand = [n for n in z.namelist() if n.endswith("Metadata/global-metadata.dat")]
            if not cand:
                return None
            with open(meta, "wb") as f:
                f.write(z.read(cand[0]))
    except Exception:
        return None
    jf = f"/tmp/meta-{pkg}.json"
    r = run([REA, "inspect-il2cpp-metadata", meta, "--json"])
    with open(jf, "w") as f:
        f.write(r.stdout)
    try:
        d = json.load(open(jf))
        n = d["normalized_result"]
    except Exception:
        for p in (meta, jf):
            if os.path.exists(p):
                os.remove(p)
        return None

    types, methods = n["types"], n["methods"]
    imgs = n["images"]
    acs = next((i for i in imgs if i["name"].startswith("Assembly-CSharp")), None)
    digest = {
        "metadata_version": n.get("metadata_version"),
        "counts": {k: len(n[k]) for k in ("images", "types", "methods", "fields",
                                          "properties", "events", "parameters",
                                          "string_literals")},
        "images": [i["name"] for i in imgs if not i["name"].startswith(("System.", "Unity.", "Mono.", "mscorlib"))][:40],
    }
    if acs:
        s, c = acs["type_start"], acs["type_count"]
        game_types = types[s:s + c]
        digest["assembly_csharp"] = {
            "types": c,
            "methods": sum(t["method_count"] for t in game_types),
            "namespaces": sorted({t["namespace"] for t in game_types if t["namespace"]}),
            "template_ids": sorted({int(m.group(1)) for t in game_types
                                    if (m := re.match(r"Template(\d+)", t["name"]))}),
            "type_names": [t["name"] for t in game_types if not t["namespace"]],
            "keyword_types": sorted({f"{t['namespace']}.{t['name']}" if t["namespace"] else t["name"]
                                     for t in game_types if KEYWORD_RE.search(t["name"])}),
        }
    watch = {}
    for i, t in enumerate(types):
        if t["name"] in WATCH and not t["namespace"]:
            ms = methods[t["method_start"]:t["method_start"] + t["method_count"]]
            watch[t["name"]] = sorted({m["name"] for m in ms if not m["name"].startswith(("get_", "set_"))})
    digest["watch_methods"] = watch

    lits = set()
    for row in n.get("string_literals") or []:
        v = (row or {}).get("value") or ""
        if LITERAL_RE.match(v) and LIT_KEYWORD_RE.search(v):
            lits.add(v)
    digest["key_literals"] = sorted(lits)[:60]

    for p in (meta, jf):
        if os.path.exists(p):
            os.remove(p)
    return digest


def main():
    os.makedirs(OUT, exist_ok=True)
    pkgs = sorted(d for d in os.listdir(ACQ) if os.path.isdir(f"{ACQ}/{d}"))
    for pkg in pkgs:
        apks = sorted(f for f in os.listdir(f"{ACQ}/{pkg}") if f.endswith(".apk"))
        paths = [f"{ACQ}/{pkg}/{f}" for f in apks]
        base = next((p for p in paths if p.endswith("/base.apk")), paths[0])
        entries, signals = [], set()
        for p in paths:
            names = apk_entries(p)
            entries.append({"name": os.path.basename(p), "bytes": os.path.getsize(p),
                            "entry_count": len(names)})
            for name in names:
                for sig, fam in ENGINE_SIGS.items():
                    if sig in name:
                        signals.add(fam)
        abi_split = next((p for p in paths if "config.arm64" in p), None)
        digest = {
            "package": pkg,
            "bytes": sum(e["bytes"] for e in entries),
            "apks": entries,
            "engine": sorted(signals),
            "unity_version": unity_version(abi_split or base, apk_entries(abi_split or base)),
            "sdks": dex_sdks(base, apk_entries(base)),
            "delivery_packs": [a["name"][:-4] for a in entries
                               if a["name"] not in ("base.apk",) and not a["name"].startswith("split_config.")],
            "device": dumpsys(pkg),
        }
        digest["il2cpp"] = il2cpp_digest(pkg, base)
        with open(f"{OUT}/digest-{pkg}.json", "w") as f:
            json.dump(digest, f, indent=1)
        print(f"OK {pkg}  engine={digest['engine']} unity={digest['unity_version']} "
              f"packs={len(digest['delivery_packs'])} sdks={len(digest['sdks'])}", flush=True)


if __name__ == "__main__":
    main()
