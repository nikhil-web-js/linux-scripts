#!/bin/bash
# Fill clipboard history with item1..item9 (item1 ends up most recent / first in the menu).
set -euo pipefail

if ! command -v wl-copy >/dev/null || ! command -v wl-paste >/dev/null; then
    echo "wl-copy/wl-paste not found. Install wl-clipboard." >&2
    exit 1
fi

# The extension drops copies that arrive while it is still reading the previous
# one. Wait until this item is on the clipboard, then give the extension time
# to ingest it before the next owner-change.
copy_item() {
    local text="$1"
    printf '%s' "$text" | wl-copy -n -t text/plain

    local i pasted=""
    for i in $(seq 1 30); do
        pasted="$(wl-paste -n -t text/plain 2>/dev/null || true)"
        if [ "$pasted" = "$text" ]; then
            break
        fi
        sleep 0.1
    done

    if [ "$pasted" != "$text" ]; then
        echo "Failed to copy: $text" >&2
        exit 1
    fi

    echo "Copied $text"
    sleep 1.5
}

echo "Copying item9 → item1 (item1 will be first in the menu)..."
for i in $(seq 9 -1 1); do
    copy_item "item$i"
done

echo
echo "Done. Open the clipboard menu — you should see item1 through item9."
echo "Then try Ctrl+1 in the menu, or Ctrl+Alt+1 with the menu closed."
