#!/bin/bash
# Discover dependency manifests once and emit cache booleans + hashes.
#
# Replaces repeated `hashFiles('**/...')` evaluations, each of which walked the
# whole workspace (including .git/vendor/node_modules) on every step gate.
#
# Discovery order:
#   1. MANIFEST_LIST input (newline-separated) — supplied by an upstream
#      prepare step, no discovery needed.
#   2. `git ls-files` — reads the index, no filesystem walk, and tracked-only
#      so it skips ignored/untracked vendor & node_modules for free.
#   3. pruned `find` — fallback when the build dir is not a git checkout.
set -euo pipefail

ROOT="${BUILD_DIR}"
if [[ "$ROOT" != /* ]]; then
	ROOT="${GITHUB_WORKSPACE}/${ROOT}"
fi
cd "$ROOT"

if [ -n "${MANIFEST_LIST:-}" ]; then
	mapfile -t files <<< "$MANIFEST_LIST"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	mapfile -t files < <(git ls-files -- \
		'*composer.json' '*composer.lock' \
		'*package.json' '*pnpm-lock.yaml' '*package-lock.json' | sort)
else
	mapfile -t files < <(find . \
		\( -name .git -o -name node_modules -o -name vendor -o -path '*/wp-content/uploads' \) -prune \
		-o -type f \( -name composer.json -o -name composer.lock \
			-o -name package.json -o -name pnpm-lock.yaml -o -name package-lock.json \) -print | sort)
fi

list() { printf '%s\n' ${files[@]+"${files[@]}"}; }
has()  { list | grep -qE "(^|/)$1\$" && echo true || echo false; }
hashof() {
	local sel
	sel=$(list | grep -E "(^|/)($1)\$" || true)
	if [ -z "$sel" ]; then echo ""; return; fi
	printf '%s\n' "$sel" | xargs sha256sum | sha256sum | cut -d' ' -f1
}

{
	echo "has_composer=$(has composer.json)"
	echo "has_node=$(has package.json)"
	echo "has_pnpm=$(has pnpm-lock.yaml)"
	echo "composer_hash=$(hashof 'composer.json|composer.lock')"
	echo "node_hash=$(hashof 'package.json|pnpm-lock.yaml|package-lock.json')"
} >> "$GITHUB_OUTPUT"
