#!/bin/bash
# Kept for compatibility with the 2026 instructions: restarts the desktop.
# See scripts/desktop.sh and docs/desktop.md.
exec bash "$(dirname "${BASH_SOURCE[0]}")/desktop.sh" restart
