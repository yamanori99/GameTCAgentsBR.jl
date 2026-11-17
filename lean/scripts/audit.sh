#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.elan/bin:${PATH}"
lake build
lake env lean Audit.lean
if rg -n 'sorry|admit|native_decide|bv_decide|ofReduceBool' GameTCLean Audit 2>/dev/null; then
  echo "forbidden proof token found"
  exit 1
fi
echo "audit.sh OK"