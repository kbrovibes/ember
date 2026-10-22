#!/bin/bash
# Builds build/Ember.dmg (stable name, for the "latest" download link) and build/Ember-<version>.dmg, with checksums.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(cat VERSION)"
scripts/bundle.sh release

STAGE=build/dmg
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R build/Ember.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f build/Ember.dmg "build/Ember-$VERSION.dmg"
hdiutil create -volname "Ember" -srcfolder "$STAGE" -ov -format UDZO -fs HFS+ build/Ember.dmg >/dev/null
cp build/Ember.dmg "build/Ember-$VERSION.dmg"
(cd build && shasum -a 256 Ember.dmg "Ember-$VERSION.dmg" > Ember.dmg.sha256)
rm -rf "$STAGE"
echo "built build/Ember.dmg ($(du -h build/Ember.dmg | cut -f1))"
