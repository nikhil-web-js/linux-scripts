#!/usr/bin/env bash
set -euo pipefail

EXT_ID="clipboard-indicator@tudmotu.com"
REPO="https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator.git"
# Patch was generated against Clipboard Indicator v71.
UPSTREAM_COMMIT="c880c7f"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/clipboard-indicator-numeric-shortcuts.patch"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_ID"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "==> Checking requirements..."

command -v git >/dev/null || {
    echo "Error: git is not installed."
    exit 1
}

command -v gnome-extensions >/dev/null || {
    echo "Error: gnome-extensions command is not available."
    exit 1
}

command -v glib-compile-schemas >/dev/null || {
    echo "Error: glib-compile-schemas is not installed."
    exit 1
}

if [[ ! -f "$PATCH_FILE" ]]; then
    echo "Error: patch not found:"
    echo "  $PATCH_FILE"
    exit 1
fi

echo "==> Cloning Clipboard Indicator..."
git clone "$REPO" "$TMP_DIR/clipboard-indicator"

cd "$TMP_DIR/clipboard-indicator"

echo "==> Checking out upstream base $UPSTREAM_COMMIT..."
git checkout --quiet "$UPSTREAM_COMMIT"

echo "==> Applying numeric shortcuts patch..."
# Skip the compiled schema blob if present; we compile it below from the XML.
git apply --whitespace=nowarn --exclude=schemas/gschemas.compiled "$PATCH_FILE"

if ! grep -q "_directPasteItem" extension.js || \
   ! grep -q "direct-paste-1" schemas/org.gnome.shell.extensions.clipboard-indicator.gschema.xml || \
   ! grep -q "ci-number-label" stylesheet.css; then
    echo "Error: patch applied, but numeric shortcuts were not found in the tree."
    exit 1
fi

echo "==> Compiling GSettings schema..."
glib-compile-schemas schemas/

if [[ ! -f schemas/gschemas.compiled ]]; then
    echo "Error: schema compilation did not produce schemas/gschemas.compiled"
    exit 1
fi

echo "==> Installing extension..."
mkdir -p "$(dirname "$EXT_DIR")"

# Disable existing extension before replacing it.
gnome-extensions disable "$EXT_ID" 2>/dev/null || true

rm -rf "$EXT_DIR"
cp -a "$TMP_DIR/clipboard-indicator" "$EXT_DIR"
rm -rf "$EXT_DIR/.git"

echo "==> Enabling extension..."
gnome-extensions enable "$EXT_ID"

echo
echo "=========================================="
echo " Clipboard Indicator installed successfully"
echo " Numeric shortcuts patch applied"
echo "=========================================="
echo
echo "New features:"
echo "  Ctrl+1-9:       Paste item 1-9 (in menu)"
echo "  Ctrl+Alt+1-9:   Direct paste item 1-9"
echo "  Number labels:  Show 1-9 next to items"
echo
echo "Recommended settings:"
echo "  Paste on select:                 ON"
echo "  Move item to top after selection: ON"
echo
echo "IMPORTANT: On Wayland, log out and log back in so GNOME"
echo "picks up the new shortcut schema. Number labels should"
echo "appear after this install; global Ctrl+Alt+1-9 may not"
echo "until you restart the session."
echo
echo "Test with:"
echo "  cd $EXT_DIR"
echo "  ./populate_clipboard.sh"
