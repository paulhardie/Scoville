#!/usr/bin/env bash
# Exports the phone build, then serves it on the LAN. `--no-export` serves the
# last build as it is; other arguments go to serve_web.py (e.g. --port 8070).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "${1:-}" = "--no-export" ]; then
	shift
else
	bash "${ROOT}/tools/export_web.sh"
fi
exec python3 "${ROOT}/tools/serve_web.py" "$@"
