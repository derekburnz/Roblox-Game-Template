#!/usr/bin/env bash
# The done gate (macOS, Linux, Git Bash on Windows). Run from this folder: ./check.sh
# It runs the same four checks CI runs on every pull request:
#   rojo sourcemap  proves the Rojo project file still maps every folder
#   luau-lsp        type-checks the Luau against the Roblox API
#   selene          lints for common mistakes (unused variables, bad API use)
#   stylua --check  fails when a file is not formatted
set -euo pipefail
cd "$(dirname "$0")"

step() { echo "== $1"; shift; "$@"; }

step "rojo sourcemap" rojo sourcemap default.project.json -o sourcemap.json

# Roblox API types must come from the same luau-lsp version that parses them (newer files use syntax
# older releases reject), so they are fetched from the tag matching `luau-lsp --version`.
TYPES=globalTypes.None.d.luau
LSP_VERSION=$(luau-lsp --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
if [ ! -f "$TYPES" ] || [ "$(cat .types-version 2>/dev/null)" != "$LSP_VERSION" ]; then
  echo "Downloading Roblox API types for luau-lsp $LSP_VERSION (once per version)..."
  curl -fsSL -o "$TYPES" "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$LSP_VERSION/scripts/globalTypes.None.d.luau"
  echo "$LSP_VERSION" > .types-version
fi

step "luau-lsp analyze" luau-lsp analyze --sourcemap=sourcemap.json --definitions="$TYPES" --ignore "Packages/**" --ignore "ServerPackages/**" --ignore "src/server/Vendor/**" src
step "selene" selene src
# --respect-ignores: given an explicit path, StyLua skips .styluaignore unless told, and would reformat Vendor/.
step "stylua --check" stylua --check --respect-ignores src
rm -f sourcemap.json
echo "All checks passed."
