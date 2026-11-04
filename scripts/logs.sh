#!/usr/bin/env bash
# e21s04 — Diário local do jogo para pais e agentes.
#   bash scripts/logs.sh path|tail|summary|audit [--target sim] [--dir DIR]
# Detalhes: scripts/log_tool.py --help. Nada sai do computador.
set -euo pipefail
exec python3 -I "$(cd "$(dirname "$0")" && pwd)/log_tool.py" "$@"
