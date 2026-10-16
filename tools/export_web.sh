#!/usr/bin/env bash
# Exports the phone build: the Web preset in export_presets.cfg (single-threaded,
# PWA) to build/web/index.html. Offline.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/build/web"
VERSION="$(tr -d '[:space:]' < "${ROOT}/.godot-version")"   # 4.7.2-stable
TEMPLATE_DIR="${VERSION/-/.}"                                # 4.7.2.stable

have_templates=0
for base in "${HOME}/Library/Application Support/Godot" "${XDG_DATA_HOME:-${HOME}/.local/share}/godot"; do
	if [ -f "${base}/export_templates/${TEMPLATE_DIR}/web_nothreads_release.zip" ]; then
		have_templates=1
	fi
done
if [ "${have_templates}" -ne 1 ]; then
	echo "export_web.sh: Godot ${VERSION}'s Web export template isn't installed (web_nothreads_release.zip)." >&2
	echo "  In the Godot editor: Editor > Manage Export Templates > Download and Install (${TEMPLATE_DIR})." >&2
	exit 2
fi

# Import first so a fresh clone has its resource cache; an export won't do it
# for every script and the first run would otherwise fail with missing classes.
bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" --import >/dev/null 2>&1 || true

rm -rf "${OUT}"
mkdir -p "${OUT}"
log="$(bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" --export-release "Web" "${OUT}/index.html" 2>&1)" || {
	printf '%s\n' "${log}" >&2
	echo "export_web.sh: the export failed (output above)." >&2
	exit 1
}
if printf '%s\n' "${log}" | grep -E '^ERROR:|SCRIPT ERROR|Parse Error' >/dev/null; then
	printf '%s\n' "${log}" >&2
	echo "export_web.sh: Godot reported errors during the export." >&2
	exit 1
fi

for f in index.html index.js index.wasm index.pck; do
	if [ ! -s "${OUT}/${f}" ]; then
		printf '%s\n' "${log}" >&2
		echo "export_web.sh: ${f} was not written to ${OUT}." >&2
		exit 1
	fi
done
echo "Exported the Web build to ${OUT} ($(du -sh "${OUT}" | cut -f1))."
