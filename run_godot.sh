#!/usr/bin/env bash
set -euo pipefail
# Godot resolves user://, where the real save sits, under $HOME. Point it at a
# scratch folder so no run (tests, bots, headless boot) can touch that save. On
# macOS HOME is the only override Godot honours; the XDG_* variables are ignored.
#
# Which Godot: $GODOT if set; else the pinned copy tools/install_godot_linux.sh
# puts in ~/.cache/scoville/godot (what CI runs); else the owner's Mac app;
# else `godot` on PATH.
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_GODOT="/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot"
CACHED_GODOT="${GODOT_INSTALL_DIR:-${HOME}/.cache/scoville/godot}/godot-$(tr -d '[:space:]' < "${ROOT}/.godot-version")"
if [ -n "${GODOT:-}" ]; then
	GODOT_BIN="${GODOT}"
elif [ -x "${CACHED_GODOT}" ]; then
	GODOT_BIN="${CACHED_GODOT}"
elif [ -x "${MAC_GODOT}" ]; then
	GODOT_BIN="${MAC_GODOT}"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
else
	echo "run_godot.sh: no Godot found. Set GODOT, or on Linux run: bash tools/install_godot_linux.sh" >&2
	exit 127
fi
# macOS TMPDIR ends in "/"; a doubled slash in HOME breaks Godot's listing of
# user://, so test clean-up silently does nothing. Strip it.
SCRATCH="${TMPDIR:-/tmp}"
REAL_HOME="${HOME}"
export HOME="${SCRATCH%/}/scoville-home"
mkdir -p "${HOME}"
# Export templates sit under the user data folder too, so a scratch HOME hides
# them. Link the real ones in (read-only for our purposes) so tools/export_web.sh
# can export without any run being able to reach the real save.
for dir in "Library/Application Support/Godot" ".local/share/godot"; do
	if [ -d "${REAL_HOME}/${dir}/export_templates" ]; then
		mkdir -p "${HOME}/${dir}"
		link="${HOME}/${dir}/export_templates"
		# Godot may have made an empty folder there; rmdir only removes an empty one.
		if [ -d "${link}" ] && [ ! -L "${link}" ]; then
			rm -f "${link}/export_templates"
			rmdir "${link}" 2>/dev/null || true
		fi
		ln -sfn "${REAL_HOME}/${dir}/export_templates" "${link}"
	fi
done
exec "${GODOT_BIN}" "$@"
