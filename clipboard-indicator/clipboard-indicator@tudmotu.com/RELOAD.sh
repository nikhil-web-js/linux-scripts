#!/bin/bash
# Quick reload script for the extension

echo "Disabling extension..."
gnome-extensions disable clipboard-indicator@tudmotu.com

echo "Waiting 1 second..."
sleep 1

echo "Re-enabling extension..."
gnome-extensions enable clipboard-indicator@tudmotu.com

echo "Done! Extension reloaded."
echo ""
echo "To test:"
echo "1. Open Clipboard Indicator menu"
echo "2. You should see numbers 1-9 next to the first 9 items"
echo "3. Press Ctrl+1, Ctrl+2, etc. to select items"
echo "4. Try searching - numbers update for filtered results"
echo ""
echo "Watch for errors:"
echo "  journalctl -f -o cat /usr/bin/gnome-shell | grep -i clipboard"
