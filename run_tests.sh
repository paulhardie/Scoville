#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# I1 (SKELETON.md): tools/ipm/mapping.json, which skeleton_tests.gd checks the
# data against, must be what mapping.py makes of the snapshot today.
fresh="$(mktemp -d)"
python3 -I "${ROOT}/tools/ipm/mapping.py" "${ROOT}/docs/ipm_snapshot.json" "${fresh}" >/dev/null
if ! cmp -s "${fresh}/mapping.json" "${ROOT}/tools/ipm/mapping.json"; then
	echo "FAIL: tools/ipm/mapping.json is stale; rerun tools/ipm/mapping.py" >&2
	exit 1
fi
rm -rf "${fresh}"
# A runtime error aborts only the test function it happens in; the suite keeps
# going and can still print PASS and exit 0. So any error line fails the run.
# Every suite runs, so a measured FAIL in one doesn't hide the others; any
# failure fails the run at the end.
failed=()
for suite in "${ROOT}"/tests/*_tests.gd; do
	name="$(basename "${suite}")"
	status=0
	# A script that fails to compile leaves Godot idling instead of quitting; the
	# frame cap ends it, and the PASS check below catches it.
	output="$(bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" --quit-after 20000 -s "res://tests/${name}" 2>&1)" || status=$?
	printf '%s\n' "${output}"
	if [ "${status}" -ne 0 ]; then
		echo "FAIL: ${name} exited ${status}" >&2
		failed+=("${name}")
	elif printf '%s\n' "${output}" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:' >/dev/null; then
		echo "FAIL: Godot reported errors during ${name}" >&2
		failed+=("${name}")
	elif ! printf '%s\n' "${output}" | grep -E '^PASS: ' >/dev/null; then
		echo "FAIL: ${name} never reported PASS" >&2
		failed+=("${name}")
	fi
done
if [ "${#failed[@]}" -gt 0 ]; then
	echo "FAIL: ${failed[*]}" >&2
	exit 1
fi
