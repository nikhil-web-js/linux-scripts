# Clipboard Indicator - Numeric Shortcuts Implementation Status

## Goal
Add numeric quick-selection shortcuts to Clipboard Indicator extension:
1. **Ctrl+1-9 in menu**: While clipboard menu is open, press Ctrl+Number to paste the Nth visible item
2. **Ctrl+Alt+1-9 direct paste**: Press Ctrl+Alt+Number to paste directly without opening menu
3. **Number labels 1-9**: Display numbers next to first 9 visible items in menu

## Current Status: TESTING FIX

### What's Working ✅
- Number labels (1-9) display correctly next to items in menu
- CSS styling for number labels
- `_updateNumberLabels()` dynamically updates when items filtered/moved/removed
- Schema entries for direct-paste-1 through direct-paste-9
- Constants in constants.js
- Prefs UI for shortcuts
- Keybindings registered and callbacks triggered
- Logs confirm methods are being called

### What's NOT Working ❌
- **Ctrl+1-9 in menu**: Doesn't paste
- **Ctrl+Alt+1-9 direct paste**: Doesn't paste (copies to clipboard but paste doesn't happen)

### Root Cause Identified
The virtual keyboard sends Shift+Insert keystrokes, but **there's no focused window to receive them**:
- When 'v' key is pressed: menuItem.actor has focus, works ✅
- When Ctrl+Number pressed from search: searchEntry has focus, NOT target window ❌
- When Ctrl+Alt+Number pressed: extension has focus, NOT target window ❌
- The Shift+Insert keypress is sent but goes nowhere

### Solution Implemented (NEEDS TESTING)
Modified `#pasteItem` method:
1. Update clipboard
2. **Close menu first** (returns focus to previously focused window)
3. Wait 150ms (increased from 50ms) for focus to return
4. THEN send Shift+Insert keystrokes

The key is: menu.close() must happen BEFORE setTimeout, and we need longer delay for focus transfer.

## Testing Instructions
1. Compile schema: `make compile-settings`
2. **Logout and login** (required on Wayland)
3. Populate clipboard: `./populate_clipboard.sh`
4. Test Ctrl+Alt+3 from browser address bar (should paste item3)
5. Test open menu with Super+V, then Ctrl+2 (should paste item2)
6. Check logs: `journalctl -f -o cat /usr/bin/gnome-shell | grep "Clipboard Indicator"`

## User Environment
- **OS**: Wayland (not X11)
- **Settings**: Paste on select = ON, Move item to top = ON
- **Note**: Changes require logout/login, cannot use Alt+F2+'r'

## Files Modified
- `extension.js`: Main implementation
- `schemas/org.gnome.shell.extensions.clipboard-indicator.gschema.xml`: Keybinding definitions
- `constants.js`: Field constants
- `prefs.js`: UI for shortcuts
- `stylesheet.css`: Number label styling
- `keyboard.js`: Virtual keyboard (unchanged, uses Clutter virtual device)

## Next Steps
1. Test the fix (requires user logout/login)
2. If still not working: Check if menu.close() actually returns focus
3. Alternative approach if this fails: Try `Main.panel.menuManager._grabber` or focus manipulation
