#!/bin/bash
# Source me. Sets up the toolchain.
#
# If Xcode's license isn't accepted, xcrun/git/swift shims fail (xcrun prints the error but exits 0),
# so fall back to the Command Line Tools. The CLT lacks the SwiftUI/Testing macro plugins (@State etc.),
# so borrow them from Xcode.app via -plugin-path. Once the license is accepted this all becomes a no-op.
SWIFT_FLAGS=()
if [ -z "${DEVELOPER_DIR:-}" ] && { xcrun --find swift 2>&1 || true; } | grep -qi "license"; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
  XCODE_PLUGINS=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins
  [ -d "$XCODE_PLUGINS" ] && SWIFT_FLAGS=(-Xswiftc -plugin-path -Xswiftc "$XCODE_PLUGINS")
fi
