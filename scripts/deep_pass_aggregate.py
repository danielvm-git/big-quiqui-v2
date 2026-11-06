#!/usr/bin/env python3
"""Aggregate the 24 per-package digests into cross-title facts."""
import collections
import glob
import json
import os
import re
import zipfile

ROOT = "/Users/danielvm/Developer/big-quiqui-v2"
REPORT = f"{ROOT}/.rea/report"
BOGUS = {"2018.3.0a1"}


def real_unity(apk, names):
    target = next((n for n in names if n.endswith("libunity.so")), None)
    if not target:
        return None
    with zipfile.ZipFile(apk) as z:
        blob = z.read(target)
    found = {f.decode() for f in re.findall(rb"20\d\d\.\d+\.\d+[abfp]\d+", blob)} - BOGUS
    return max(found, key=lambda v: [int(x) for x in re.findall(r"\d+", v)]) if found else None


def short(pkg):
    return pkg.replace("com.tutotoons.app.", "").replace("air.com.tutotoons.app.", "air:").replace(".free", "")


ds = [json.load(open(p)) for p in sorted(glob.glob(f"{REPORT}/digest-*.json"))]
ds.sort(key=lambda d: -d["bytes"])

# repair unity versions
for d in ds:
    apks = [f"{ROOT}/.rea/acq/{d['package']}/{a['name']}" for a in d["apks"]]
    abi = next((a for a in apks if "config.arm64" in a), apks[0])
    with zipfile.ZipFile(abi) as z:
        d["unity_version"] = real_unity(abi, z.namelist())

print(f"packages: {len(ds)}  total: {sum(d['bytes'] for d in ds)/1e9:.2f} GB  "
      f"apks: {sum(len(d['apks']) for d in ds)}\n")

hdr = f"{'title':34s} {'MB':>6s} {'apk':>4s} {'packs':>5s} {'meta':>4s} {'ACS':>5s} {'mth':>5s} {'tmpl':>9s} {'unity':>12s}"
print(hdr)
print("-" * len(hdr))
for d in ds:
    il = d["il2cpp"] or {}
    acs = (il.get("assembly_csharp") or {})
    tm = acs.get("template_ids") or []
    tr = f"{min(tm)}-{max(tm)}" if tm else "-"
    print(f"{short(d['package']):34s} {d['bytes']/1e6:6.0f} {len(d['apks']):4d} "
          f"{len(d['delivery_packs']):5d} {str(il.get('metadata_version')):>4s} "
          f"{acs.get('types', 0):5d} {acs.get('methods', 0):5d} {tr:>9s} "
          f"{str(d['unity_version']):>12s}")

print("\n=== type frequency across titles (Assembly-CSharp) ===")
freq = collections.Counter()
for d in ds:
    acs = (d["il2cpp"] or {}).get("assembly_csharp") or {}
    for t in set(acs.get("type_names") or []):
        freq[t] += 1
n = len(ds)
print(f"\n-- in ALL {n} titles ({sum(1 for t,c in freq.items() if c==n)} types) --")
core = sorted((t for t, c in freq.items() if c == n), key=lambda t: -freq[t])
print(", ".join(core))
print(f"\n-- in >=80% of titles, not all --")
print(", ".join(sorted(t for t, c in freq.items() if c < n and c >= 0.8 * n)))
print(f"\n-- rare (<=3 titles) --")
print(", ".join(sorted(t for t, c in freq.items() if c <= 3))[:1200])

print("\n=== namespaces ===")
ns = collections.Counter()
for d in ds:
    acs = (d["il2cpp"] or {}).get("assembly_csharp") or {}
    for x in acs.get("namespaces") or []:
        ns[x] += 1
for k, v in ns.most_common():
    print(f"{v:3d}/{n}  {k}")

print("\n=== watch method sets (union across titles) ===")
wm = collections.defaultdict(lambda: collections.Counter())
for d in ds:
    for t, ms in ((d["il2cpp"] or {}).get("watch_methods") or {}).items():
        for m in ms:
            wm[t][m] += 1
for t in sorted(wm, key=lambda t: -max(wm[t].values())):
    tot = sum(1 for d in ds if t in ((d["il2cpp"] or {}).get("watch_methods") or {}))
    stable = [m for m, c in wm[t].most_common() if c == tot]
    print(f"\n{t} ({tot}/{n} titles, {len(stable)} shared methods)")
    print("   " + ", ".join(stable))

print("\n=== SDK surface ===")
sdk = collections.Counter()
for d in ds:
    for s in d["sdks"]:
        sdk[s] += 1
for k, v in sdk.most_common():
    print(f"{v:3d}/{n}  {k}")
print("-- differences --")
for d in ds:
    std = set(sdk)
    if set(d["sdks"]) != std:
        print(f"  {short(d['package'])}: missing {sorted(std - set(d['sdks']))}")

print("\n=== device facts ===")
for d in ds:
    dv = d["device"]
    print(f"{short(d['package']):30s} v{dv.get('targetSdk')}/{dv.get('minSdk')} "
          f"{dv.get('versionName')} inst={dv.get('installer')} first={dv.get('firstInstall')}")

print("\n=== permissions union ===")
pu = collections.Counter()
for d in ds:
    for p in d["device"].get("permissions_granted") or []:
        pu[p] += 1
for k, v in pu.most_common():
    print(f"{v:3d}/{n}  {k}")

print("\n=== delivery packs by title (name pattern) ===")
for d in ds:
    if d["delivery_packs"]:
        print(f"\n{short(d['package'])} ({len(d['delivery_packs'])}):")
        print("   " + ", ".join(d["delivery_packs"])[:1500])

print("\n=== key literals (per title, deduped) ===")
seen = {}
for d in ds:
    for lit in (d["il2cpp"] or {}).get("key_literals") or []:
        seen.setdefault(lit, 0)
        seen[lit] += 1
common = [k for k, v in seen.items() if v >= n // 2]
print(f"\n-- in >=50% of titles ({len(common)}) --")
print(", ".join(sorted(common))[:2500])
print(f"\n-- unique to one title ({sum(1 for v in seen.values() if v==1)}) --")
print(", ".join(sorted(k for k, v in seen.items() if v == 1))[:1500])
