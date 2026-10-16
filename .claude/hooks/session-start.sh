#!/usr/bin/env bash
# Session start: make the tests and tools runnable before work starts.
# - Cloud (Linux) sessions: install the pinned Godot (tools/install_godot_linux.sh),
#   tell the session where it is, and import the project once so the cache is fresh.
# - Local sessions: check the Godot run_godot.sh would use matches .godot-version,
#   and say so if it doesn't. Never installs anything locally.
# Safe to run again, and never touches a real save (every run goes through run_godot.sh).
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${ROOT}"
pinned="$(tr -d '[:space:]' < .godot-version)"

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
	godot="$(bash tools/install_godot_linux.sh)"
	if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
		echo "export GODOT=\"${godot}\"" >> "${CLAUDE_ENV_FILE}"
	fi
	if [ ! -d .godot ]; then
		GODOT="${godot}" bash run_godot.sh --headless --path . --import >/dev/null 2>&1 || true
	fi
	echo "Godot ready: ${godot}"
	exit 0
fi

found="$(bash run_godot.sh --version 2>/dev/null | head -1 || true)"
# Godot prints e.g. 4.7.2.stable.official.ed1daf0bf; the pin is 4.7.2-stable.
if [ -z "${found}" ]; then
	echo "No Godot found for run_godot.sh. Set GODOT to a ${pinned} binary."
elif [ "${found#"${pinned/-/.}"}" = "${found}" ]; then
	echo "Warning: Godot ${found} doesn't match the pinned ${pinned}. Results may differ from CI."
else
	echo "Godot ${found} matches the pin."
fi
