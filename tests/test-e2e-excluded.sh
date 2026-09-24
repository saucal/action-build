#!/usr/bin/env bash
# A site's Playwright suite lives in e2e/ as its own package. The deploy build must never install,
# build or test it: without a pnpm-workspace.yaml, `pnpm recursive` descends into every
# sub-package (measured on pnpm 6/8/10), so e2e's lifecycle scripts and `test` would run on
# every deploy and its private @saucal/woolverine install would fail with no token.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
say() { echo "FAIL: $*"; fail=1; }
command -v npx >/dev/null || { echo "SKIP: no npx"; exit 0; }
command -v jq >/dev/null  || { echo "SKIP: no jq (build-for-deployment.sh reads package.json with it)"; exit 0; }

fixture() { # <dir> [workspace]
	mkdir -p "$1/e2e" "$1/plugins/a"
	echo '{"name":"site","version":"1.0.0","scripts":{"build":"echo ROOT-BUILD"}}' > "$1/package.json"
	echo '{"name":"a","version":"1.0.0","scripts":{"build":"echo PLUGIN-BUILD"}}' > "$1/plugins/a/package.json"
	echo '{"name":"suite","version":"1.0.0","scripts":{"preinstall":"echo E2E-PREINSTALL","build":"echo E2E-BUILD","test":"echo E2E-TEST"}}' > "$1/e2e/package.json"
	[ "${2:-}" = workspace ] && printf 'packages:\n  - "plugins/*"\n' > "$1/pnpm-workspace.yaml"
	return 0
}

for v in 6 10; do
	mkdir -p "$T/bin$v"; printf '#!/bin/sh\nexec npx -y pnpm@%s "$@"\n' "$v" > "$T/bin$v/pnpm"; chmod +x "$T/bin$v/pnpm"
	for mode in plain workspace; do
		d="$T/pnpm$v-$mode"; fixture "$d" "$mode"
		( cd "$d" && PATH="$T/bin$v:$PATH" pnpm install --lockfile-only >/dev/null 2>&1 )
		# pnpm 6 writes no lockfile for a dependency-free tree; the build only needs the file to take its pnpm path
		[ -f "$d/pnpm-lock.yaml" ] || : > "$d/pnpm-lock.yaml"
		out="$(cd "$d" && PATH="$T/bin$v:$PATH" bash "$ROOT/build-for-deployment.sh" 2>&1)" || say "pnpm $v $mode: the build failed: $(printf '%s' "$out" | tail -n 3)"
		printf '%s' "$out" | grep -qE 'E2E-(PREINSTALL|BUILD|TEST)' && say "pnpm $v $mode: the build ran e2e/ scripts"
		if [ "$mode" = plain ]; then
			printf '%s' "$out" | grep -q ROOT-BUILD || say "pnpm $v plain: the root build no longer runs"
		else
			printf '%s' "$out" | grep -q PLUGIN-BUILD || say "pnpm $v workspace: the workspace package no longer builds"
		fi
	done
done

# npm path: `npm ci` at the root never touches e2e/; pinned so a later change keeps it that way.
d="$T/npm"; fixture "$d"; rm -rf "$d/plugins"
( cd "$d" && npm install --package-lock-only >/dev/null 2>&1 )
out="$(cd "$d" && bash "$ROOT/build-for-deployment.sh" 2>&1)" || say "npm: the build failed: $(printf '%s' "$out" | tail -n 3)"
printf '%s' "$out" | grep -qE 'E2E-(PREINSTALL|BUILD|TEST)' && say "npm: the build ran e2e/ scripts"

[ "$fail" -eq 0 ] && echo "PASS: e2e/ stays out of deploy builds"
exit "$fail"
