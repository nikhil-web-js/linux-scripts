#!/bin/bash

set -e

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/fullscreen-workspace@local"

mkdir -p "$EXT_DIR"

cp extension.js "$EXT_DIR/"
cp metadata.json "$EXT_DIR/"

gnome-extensions disable fullscreen-workspace@local 2>/dev/null || true
gnome-extensions enable fullscreen-workspace@local

gnome-extensions install --force ./hidetopbar-fullscreen@local.zip
gnome-extensions enable hidetopbar-fullscreen@local

echo "Fullscreen Workspace extension installed and reloaded."