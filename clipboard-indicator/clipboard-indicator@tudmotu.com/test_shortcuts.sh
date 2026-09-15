#!/bin/bash

echo "=== Clipboard Indicator Shortcuts Test ==="
echo ""

echo "1. Checking if schema is loaded..."
if gsettings list-keys org.gnome.shell.extensions.clipboard-indicator &>/dev/null; then
    echo "✅ Schema loaded"
    echo ""
    echo "Checking direct-paste bindings:"
    for i in {1..9}; do
        binding=$(gsettings get org.gnome.shell.extensions.clipboard-indicator direct-paste-$i)
        echo "  direct-paste-$i: $binding"
    done
else
    echo "❌ Schema NOT loaded"
    echo "Run: make compile-settings"
fi

echo ""
echo "2. Checking if extension is enabled..."
if gnome-extensions list --enabled | grep clipboard-indicator; then
    echo "✅ Extension enabled"
else
    echo "❌ Extension NOT enabled"
fi

echo ""
echo "3. Test instructions:"
echo "   - Populate clipboard with test items: ./populate_clipboard.sh"
echo "   - Open menu with Super+V"
echo "   - Try Ctrl+2 (should paste item2)"
echo "   - Try Ctrl+Alt+3 without menu (should paste item3)"
echo ""
echo "4. Watch logs while testing:"
echo "   journalctl -f -o cat /usr/bin/gnome-shell | grep 'Clipboard Indicator'"
