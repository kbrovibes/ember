#!/bin/bash
# Build and launch Ember.
set -euo pipefail
cd "$(dirname "$0")/.."
pkill -x Ember 2>/dev/null || true
scripts/bundle.sh "${1:-release}"
open build/Ember.app
