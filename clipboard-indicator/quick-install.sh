#!/usr/bin/env bash
set -euo pipefail

EXT_ID="clipboard-indicator@tudmotu.com"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/$EXT_ID"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_ID"

echo "==> Quick Install (using precompiled extension)..."

command -v gnome-extensions >/dev/null || {
    echo "Error: gnome-extensions command is not available."
    exit 1
}

command -v glib-compile-schemas >/dev/null || {
    echo "Error: glib-compile-schemas is not installed."
    echo "Install with: sudo apt install libglib2.0-dev"
    exit 1
}

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Precompiled extension not found:"
    echo "  $SOURCE_DIR"
    echo ""
    echo "Use ./install.sh to download and patch from upstream instead."
    exit 1
fi

echo "==> Installing extension from precompiled source..."
mkdir -p "$(dirname "$EXT_DIR")"

# Disable existing extension before replacing it.
gnome-extensions disable "$EXT_ID" 2>/dev/null || true

rm -rf "$EXT_DIR"
cp -a "$SOURCE_DIR" "$EXT_DIR"

echo "==> Compiling GSettings schema..."
cd "$EXT_DIR"
glib-compile-schemas schemas/

echo "==> Reloading extension..."
sleep 1
gnome-extensions enable "$EXT_ID"
sleep 1

# Force reload by disabling and re-enabling
echo "==> Force reloading to apply shortcuts..."
gnome-extensions disable "$EXT_ID"
sleep 1
gnome-extensions enable "$EXT_ID"

echo
echo "=========================================="
echo " ✓ Clipboard Indicator installed (quick)"
echo "=========================================="
echo
echo "Features included:"
echo "  • Ctrl+1-9:       Paste item 1-9 (in menu)"
echo "  • Ctrl+Alt+1-9:   Direct paste item 1-9"
echo "  • Number labels:  Show 1-9 next to items"
echo
echo "Recommended settings:"
echo "  • Paste on select:                 ON"
echo "  • Move item to top after selection: ON"
echo
echo "NOTE: If shortcuts don't work, log out and log back in."
echo
echo "Test with:"
echo "  cd $EXT_DIR"
echo "  ./populate_clipboard.sh"
