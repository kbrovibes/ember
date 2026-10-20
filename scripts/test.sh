#!/bin/bash
# Runs the unit tests. Retries when the Swift Testing macro plugin fails to load,
# which happens intermittently on a cold plugin server (seen with the CLT toolchain).
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

for attempt in 1 2 3; do
  out="$(swift test ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"} 2>&1)"
  if grep -q "plugin for module 'TestingMacros' not found" <<<"$out"; then
    echo "TestingMacros plugin flake (attempt $attempt), retrying..." >&2
    continue
  fi
  grep -E "✘|error:|Test run with" <<<"$out" | cut -c1-200
  grep -q "✘\|error:" <<<"$out" && exit 1
  exit 0
done
echo "tests could not run: TestingMacros plugin kept failing" >&2
exit 1
