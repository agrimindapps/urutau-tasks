#!/usr/bin/env bash
# Smoke Web automatizado (spec 10, gate bloqueante no Chrome Stable).
#
# Pré-requisitos:
#   - chromedriver compatível com o Chrome Stable no PATH
#     (https://googlechromelabs.github.io/chrome-for-testing/)
#   - Chrome Stable instalado
#
# Uso: ./tool/web-smoke.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CHROMEDRIVER_BIN="${CHROMEDRIVER:-$(command -v chromedriver || true)}"
if [[ -z "$CHROMEDRIVER_BIN" ]]; then
  echo "chromedriver não encontrado no PATH. Instale-o (chrome-for-testing)." >&2
  exit 1
fi

CHROME_BIN="${CHROME_BINARY:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
PORT="${CHROMEDRIVER_PORT:-4444}"

if ! curl -fsS "http://127.0.0.1:${PORT}/status" >/dev/null 2>&1; then
  echo "Iniciando chromedriver na porta ${PORT}..."
  "$CHROMEDRIVER_BIN" --port="$PORT" >/dev/null 2>&1 &
  sleep 2
fi

exec flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_smoke_test.dart \
  -d web-server \
  --browser-name chrome \
  --chrome-binary "$CHROME_BIN"
