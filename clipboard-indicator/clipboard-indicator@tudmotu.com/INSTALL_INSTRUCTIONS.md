# Installation Instructions

## Manual Installation (Recommended)

Since you're already in the extension directory, the files are already in place. You just need to reload the extension:

### Method 1: Restart GNOME Shell
**X11:**
```bash
# Press Alt+F2, type 'r' and press Enter
```

**Wayland:**
```bash
# Log out and log back in
```

### Method 2: Disable and Re-enable Extension
```bash
# Disable the extension
gnome-extensions disable clipboard-indicator@tudmotu.com

# Re-enable the extension
gnome-extensions enable clipboard-indicator@tudmotu.com
```

## Compile Settings (Required if schema changed)

Since we didn't modify the schema, this is optional but recommended:

```bash
make compile-settings
```

This compiles the GSettings schema files in the `schemas/` directory.

## Verify Installation

```bash
# Check if extension is enabled
gnome-extensions list --enabled | grep clipboard-indicator

# Check for any errors
journalctl -f -o cat /usr/bin/gnome-shell
```

## New Feature: Numeric Quick-Selection

### Usage:
- Open the Clipboard Indicator menu
- Press **Ctrl+1** through **Ctrl+9** to select items 1-9
- Numbers 1-9 are displayed next to visible items
- Works with search filtering (selects from filtered results)
- **Works even when search field is focused** - you can type to search, then Ctrl+Number to select
- With "Paste on select" ON: immediately pastes the item
- With "Move item to top after selection" ON: moves selected item to top

### Notes:
- Only first 9 visible items show numbers
- Numbers update dynamically when:
  - Menu opens
  - Search filters items
  - Items are added/removed/moved/pinned
- Preserves PR #619 race-condition fix
- Ctrl+Number works in all contexts: terminals, browsers, web forms, etc.
