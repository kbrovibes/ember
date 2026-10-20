#!/bin/bash
# Source me. Falls back to Command Line Tools when Xcode's license isn't accepted yet
# (xcrun prints the license error but exits 0, so match on its output).
if [ -z "${DEVELOPER_DIR:-}" ] && { xcrun --find swift 2>&1 || true; } | grep -qi "license"; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi
