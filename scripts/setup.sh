#!/usr/bin/env bash
# Prepara o ambiente de desenvolvimento. Idempotente: rodar de novo não muda nada
# nem dá erro. Não instala o Godot (baixe 4.7 em godotengine.org).
set -euo pipefail
cd "$(dirname "$0")/.."

need() { command -v "$1" >/dev/null 2>&1 || { echo "falta: $1 — $2"; exit 1; }; }
need godot "instale o Godot 4.7 e coloque no PATH"
need python3 "instale Python 3"
need node "instale Node.js (hooks de commit)"

case "$(godot --version)" in
  4.7*) echo "ok: godot $(godot --version)";;
  *) echo "aviso: projeto usa Godot 4.7, encontrado $(godot --version)";;
esac

# One source of truth for dev tooling: requirements-dev.txt (CI and Dependabot read it too).
if command -v gdlint >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  echo "ok: gdtoolkit + PyYAML já instalados"
else
  python3 -m pip install --user -r requirements-dev.txt
fi

if [ -d node_modules/husky ]; then
  echo "ok: dependências npm já instaladas"
else
  git config core.hooksPath .githooks
  echo "ok: git hooks -> .githooks (pre-commit, commit-msg)"
fi

mkdir -p build/captures
godot --headless --path game --import >/dev/null 2>&1 && echo "ok: projeto importado"
bash scripts/logs.sh audit --self-test >/dev/null && echo "ok: auditoria de logs funcionando"
echo "pronto"
