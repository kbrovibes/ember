#!/bin/bash
# Bumps VERSION, commits, and tags. Pushing the tag is what triggers the Release workflow.
#   scripts/release.sh [patch|minor|major]     (default: patch)
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

[ -z "$(git status --porcelain)" ] || { echo "Working tree not clean; commit or stash first." >&2; exit 1; }

IFS=. read -r major minor patch < VERSION
case "${1:-patch}" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "usage: scripts/release.sh [patch|minor|major]" >&2; exit 2 ;;
esac
NEW="$major.$minor.$patch"

echo "$NEW" > VERSION
git add VERSION
git commit -q -m "Release v$NEW"
git tag -a "v$NEW" -m "Ember $NEW"
echo "Tagged v$NEW. Publish it with:  git push origin main --follow-tags"
