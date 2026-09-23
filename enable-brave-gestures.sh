#!/usr/bin/env bash

set -e

DESKTOP_FILE="/usr/share/applications/brave-browser.desktop"
FEATURES="--enable-features=TouchpadOverscrollHistoryNavigation --ozone-platform=wayland --disk-cache-size=8589934592"

if grep -q "TouchpadOverscrollHistoryNavigation" "$DESKTOP_FILE"; then
    echo "ℹ️ Brave gestures already enabled."
    exit 0
fi

sudo sed -i \
"s|Exec=/usr/bin/brave-browser-stable|Exec=/usr/bin/brave-browser-stable $FEATURES|g" \
"$DESKTOP_FILE"

echo "✅ Brave touchpad swipe navigation enabled."
echo "Restart Brave completely."