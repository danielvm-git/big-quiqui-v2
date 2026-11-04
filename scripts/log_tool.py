#!/usr/bin/env python3
"""e21s04 — Lê o diário local do jogo (game/scripts/autoloads/log.gd).

Comandos:
  path     [--target desktop|sim]   onde ficam os logs
  tail     [-n N]                   últimas linhas da sessão mais recente
  summary  [--sessions N]           resumo por sessão: fim limpo/crash, cenas, etapas, erros
  audit    [--self-test]            falha (exit 1) se algum log tiver PII ou valor fora do esquema

Opções comuns: --dir DIR (pasta de logs), --target desktop|sim.
Só biblioteca padrão; nada é enviado para lugar nenhum.
"""

from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import platform
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(ROOT, "game", "project.godot")
BUNDLE_ID = "com.bigquiqui.game"
PREFIX = "quiqui-"
REDACTED = "<redacted>"

CONTEXT_KEYS = {"ts", "t_ms", "seq", "session", "lvl", "ev", "scene", "state"}
LEVELS = {"info", "warn", "error"}
ID_RE = re.compile(r"^[a-z0-9_.:/-]{1,64}$")
PATH_RE = re.compile(r"^[A-Za-z0-9_.:/-]{1,120}$")
TS_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$")
SESSION_RE = re.compile(r"^[0-9a-f]{8}$")
PATH_KEYS = {"file", "func", "log"}
MSG_KEYS = {"msg"}
# Padrões que nunca podem aparecer em nenhum valor (PII / identificação).
FORBIDDEN = [
    ("caminho absoluto", re.compile(r"(^|[\s'\"(=])(/Users/|/home/|/var/mobile|/private/var|[A-Za-z]:\\)")),
    ("e-mail", re.compile(r"\S+@\S+\.\S+")),
    ("número longo", re.compile(r"\d{6,}")),
]


def project_name() -> str:
    with open(PROJECT, encoding="utf-8") as f:
        for line in f:
            if line.startswith("config/name="):
                return line.split("=", 1)[1].strip().strip('"')
    raise SystemExit("config/name não encontrado em game/project.godot")


def log_dir(target: str) -> str:
    if target == "sim":
        try:
            data = subprocess.run(
                ["xcrun", "simctl", "get_app_container", "booted", BUNDLE_ID, "data"],
                check=True, capture_output=True, text=True,
            ).stdout.strip()
        except (OSError, subprocess.CalledProcessError) as e:
            raise SystemExit(f"simulador sem o app {BUNDLE_ID} instalado/booted: {e}")
        return os.path.join(data, "Documents", "logs")
    name = project_name()
    if platform.system() == "Darwin":
        base = os.path.expanduser("~/Library/Application Support/Godot/app_userdata")
    elif platform.system() == "Windows":
        base = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata")
    else:
        base = os.path.expanduser("~/.local/share/godot/app_userdata")
    return os.path.join(base, name, "logs")


def session_files(directory: str) -> list[str]:
    return sorted(glob.glob(os.path.join(directory, PREFIX + "*.jsonl")), key=os.path.getmtime)


def read_lines(path: str) -> list[dict]:
    out = []
    with open(path, encoding="utf-8") as f:
        for n, raw in enumerate(f, 1):
            raw = raw.strip()
            if not raw:
                continue
            try:
                out.append(json.loads(raw))
            except json.JSONDecodeError:
                out.append({"ev": "log.unparseable", "lvl": "error", "line_no": n})
    return out


# ── tail / summary ───────────────────────────────────────────────────────────


def fmt(line: dict) -> str:
    extra = {k: v for k, v in line.items() if k not in CONTEXT_KEYS}
    ts = str(line.get("ts", ""))[11:23]
    where = f"{line.get('scene', '-')}/{line.get('state', '-')}"
    return f"{ts} {line.get('lvl', '?'):5} {line.get('ev', '?'):26} {where:22} {json.dumps(extra, ensure_ascii=False)}"


def cmd_tail(args: argparse.Namespace) -> int:
    files = session_files(args.dir)
    if not files:
        print(f"sem logs em {args.dir}")
        return 1
    for line in read_lines(files[-1])[-args.n:]:
        print(fmt(line))
    return 0


def cmd_summary(args: argparse.Namespace) -> int:
    files = session_files(args.dir)
    if not files:
        print(f"sem logs em {args.dir}")
        return 1
    sessions = [(f, read_lines(f)) for f in files]
    # Como terminou a sessão i: olhar app.exit nela, ou o relato na sessão i+1.
    endings: dict[str, str] = {}
    for _, lines in sessions:
        for line in lines:
            ev, prev = line.get("ev"), line.get("prev_session")
            if ev == "app.crash_detected" and prev:
                endings[prev] = "CRASH"
            elif ev == "app.unclean_exit" and prev:
                endings.setdefault(prev, "interrompida em primeiro plano")
            elif ev == "app.killed_in_background" and prev:
                endings.setdefault(prev, "encerrada pelo sistema em segundo plano")
    for path, lines in sessions[-args.sessions:]:
        start = lines[0] if lines else {}
        sid = start.get("session", "?")
        ended = "limpa" if any(l.get("ev") == "app.exit" for l in lines) else endings.get(sid, "sem fim registrado (ainda aberta?)")
        counts = collections.Counter(l.get("ev") for l in lines)
        print(f"\n== sessão {sid}  {start.get('ts', '?')}  {start.get('platform', '?')} v{start.get('version', '?')}  fim: {ended}")
        print(f"   arquivo: {os.path.basename(path)}  linhas: {len(lines)}")
        scenes = [l["to"] for l in lines if l.get("ev") == "scene.change"]
        if scenes:
            print("   cenas: " + " → ".join(scenes))
        states = [l["to"] for l in lines if l.get("ev") == "care.state"]
        if states:
            print("   etapas: " + " → ".join(states))
        for ev in ("scene.change_dropped", "care.state_silent"):
            for l in (l for l in lines if l.get("ev") == ev):
                print(f"   ! {ev}: {json.dumps({k: v for k, v in l.items() if k not in CONTEXT_KEYS}, ensure_ascii=False)}")
        errors = collections.Counter(
            (l.get("ev"), l.get("file"), l.get("line"), l.get("msg")) for l in lines if l.get("lvl") == "error" and l.get("ev", "").startswith("engine.")
        )
        warnings = collections.Counter(
            (l.get("ev"), l.get("file"), l.get("line"), l.get("msg")) for l in lines if l.get("ev") == "engine.warning"
        )
        for title, group in (("erros", errors), ("avisos", warnings)):
            if group:
                print(f"   {title}:")
                for (ev, f, n, msg), c in group.most_common(10):
                    print(f"     {c}x {f}:{n}  {msg}")
        others = {k: v for k, v in counts.items() if not str(k).startswith("engine.")}
        print("   eventos: " + ", ".join(f"{k}={v}" for k, v in sorted(others.items())))
    return 0


# ── audit ────────────────────────────────────────────────────────────────────


def audit_line(line: dict) -> list[str]:
    problems = []
    for key in ("ts", "session", "lvl", "ev"):
        if key not in line:
            problems.append(f"sem campo de contexto '{key}'")
    if "ts" in line and not TS_RE.match(str(line["ts"])):
        problems.append("ts fora do formato ISO UTC")
    if "session" in line and not SESSION_RE.match(str(line["session"])):
        problems.append("session não é o id aleatório de 8 hex")
    if line.get("lvl") not in LEVELS:
        problems.append(f"lvl inválido: {line.get('lvl')!r}")
    for key, value in line.items():
        if key in ("ts", "session"):
            continue
        if isinstance(value, (dict, list)):
            problems.append(f"{key}: valor composto não permitido")
            continue
        if not isinstance(value, str):
            continue
        for label, pattern in FORBIDDEN:
            if pattern.search(value):
                problems.append(f"{key}: {label}")
        if value == REDACTED or key in MSG_KEYS:
            continue
        regex = PATH_RE if key in PATH_KEYS else ID_RE
        if not regex.match(value):
            problems.append(f"{key}: texto fora do padrão de id ({value[:30]!r})")
    return problems


def audit_dir(directory: str) -> int:
    files = sorted(glob.glob(os.path.join(directory, PREFIX + "*.jsonl")))
    bad = 0
    for path in files:
        with open(path, encoding="utf-8") as f:
            for n, raw in enumerate(f, 1):
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    line = json.loads(raw)
                except json.JSONDecodeError:
                    print(f"{os.path.basename(path)}:{n}: JSON inválido")
                    bad += 1
                    continue
                for p in audit_line(line):
                    print(f"{os.path.basename(path)}:{n}: {p}")
                    bad += 1
    print(f"audit: {len(files)} arquivo(s), {bad} problema(s)")
    return 1 if bad else 0


def self_test() -> int:
    good = {"ts": "2026-11-03T01:06:44.123Z", "t_ms": 10, "seq": 1, "session": "0bbd1f8e", "lvl": "info",
            "ev": "progress.purchase", "scene": "store", "state": "vila", "item": "mesa"}
    bads = [
        dict(good, item="Maria Clara"),
        dict(good, ev="engine.error", lvl="error", msg="falhou em /Users/daniel/x.gd"),
        dict(good, item="mae@email.com"),
        dict(good, item="11987654321"),
        dict(good, session="device-ABC"),
        dict(good, extra={"nested": 1}),
    ]
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, PREFIX + "good.jsonl"), "w") as f:
            f.write(json.dumps(good) + "\n")
        if audit_dir(tmp) != 0:
            print("self-test: linha válida foi rejeitada")
            return 1
        for i, bad in enumerate(bads):
            with open(os.path.join(tmp, PREFIX + f"bad{i}.jsonl"), "w") as f:
                f.write(json.dumps(bad) + "\n")
        if audit_dir(tmp) == 0:
            print("self-test: PII passou pela auditoria")
            return 1
        caught = sum(1 for b in bads if audit_line(b))
    if caught != len(bads):
        print(f"self-test: só {caught}/{len(bads)} casos ruins detectados")
        return 1
    print(f"self-test ok: 1 linha válida aceita, {len(bads)} casos com PII rejeitados")
    return 0


def cmd_audit(args: argparse.Namespace) -> int:
    if args.self_test:
        return self_test()
    if not os.path.isdir(args.dir):
        print(f"sem logs em {args.dir} (nada a auditar)")
        return 0
    return audit_dir(args.dir)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", choices=["desktop", "sim"], default="desktop")
    parser.add_argument("--dir", help="pasta de logs (padrão: a do alvo)")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("path")
    p_tail = sub.add_parser("tail")
    p_tail.add_argument("-n", type=int, default=40)
    p_sum = sub.add_parser("summary")
    p_sum.add_argument("--sessions", type=int, default=3)
    p_audit = sub.add_parser("audit")
    p_audit.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.cmd == "audit" and args.self_test:
        return self_test()
    args.dir = args.dir or log_dir(args.target)
    if args.cmd == "path":
        print(args.dir)
        return 0
    return {"tail": cmd_tail, "summary": cmd_summary, "audit": cmd_audit}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
