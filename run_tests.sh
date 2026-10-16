#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# A runtime error aborts only the test function it happens in; the suite keeps
# going and can still print PASS and exit 0. So any error line fails the run.
for suite in "${ROOT}"/tests/*_tests.gd; do
	name="$(basename "${suite}")"
	status=0
	# A script that fails to compile leaves Godot idling instead of quitting; the
	# frame cap ends it, and the PASS check below catches it.
	output="$(bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" --quit-after 20000 -s "res://tests/${name}" 2>&1)" || status=$?
	printf '%s\n' "${output}"
	if [ "${status}" -ne 0 ]; then
		echo "FAIL: ${name} exited ${status}" >&2
		exit "${status}"
	fi
	if printf '%s\n' "${output}" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:' >/dev/null; then
		echo "FAIL: Godot reported errors during ${name}" >&2
		exit 1
	fi
	if ! printf '%s\n' "${output}" | grep -E '^PASS: ' >/dev/null; then
		echo "FAIL: ${name} never reported PASS" >&2
		exit 1
	fi
done
