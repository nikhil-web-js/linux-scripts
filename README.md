# 🐧 Linux Post-Install Setup Guide (Dual Boot + Performance)

> One-stop setup for Ubuntu after fresh install (performance + dev ready)

## Overview

This guide collects the most useful Ubuntu/Linux fixes for a fresh setup: dual-boot time sync, performance tweaks, GNOME quality-of-life settings, and common post-install troubleshooting.

## Quick Fixes

### Enable AAC codecs


```bash
sudo apt install libspa-0.2-modules-extra libfdk-aac2
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Common first steps

- Fix Windows/Ubuntu clock mismatch
- Enable ZRAM for better memory behavior
- Set up Git SSH access
- Apply GNOME tweaks for daily use

---

<details>
<summary>🔄 0. Bluetooth Toggle Shortcut (Alt+B)</summary>

Use [bluetooth/bt-toggle-shortcut.sh](bluetooth/bt-toggle-shortcut.sh) to toggle Bluetooth with a single keyboard shortcut that automatically reconnects to your devices.

### Features
- **Alt+B**: Toggle Bluetooth on/off
- Automatically reconnects to previously connected devices when turning on
- Falls back to default devices (UBON BT-370, OPPO Enco Buds3 Pro) if no stored connections
- Parallel connection attempts for faster reconnection
- Stores connected devices when turning off for smart reconnection

### Install
```bash
chmod +x bluetooth/bt-toggle-shortcut.sh
./bluetooth/bt-toggle-shortcut.sh
```

The script automatically sets up the Alt+B keybinding in GNOME.

### How It Works
- **When turning OFF**: Saves currently connected device MAC addresses
- **When turning ON**: 
  - Reconnects to previously connected devices (if stored)
  - OR attempts to connect to both default devices in parallel
  - Whichever device is in range connects first

</details>

---

<details>
<summary>🧠 1. Dual Boot Time Fix (Windows ↔ Ubuntu)</summary>

### Option A (Recommended: Ubuntu uses local time)
```bash
timedatectl set-local-rtc 1 --adjust-system-clock
timedatectl
```

### Option B (Windows uses UTC)

```cmd
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1
```

</details>

---

<details>
<summary>⚡ 2. ZRAM Setup</summary>

### Install

```bash
sudo apt install zram-tools
```

### Configure

```bash
sudo nano /etc/default/zramswap
```

```ini
ALGO=zstd
PERCENT=100
```

### Apply

```bash
sudo systemctl restart zramswap
```

### Verify

```bash
swapon --show
```

</details>

---

<details>
<summary>⚡ 3. ZSWAP (Optional)</summary>

### Enable via GRUB

```bash
sudo nano /etc/default/grub
```

```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=1 zswap.compressor=zstd"
```

```bash
sudo update-grub
```

</details>

---

<details>
<summary>💻 4. Force Git to Use SSH</summary>

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
ssh -T git@github.com
```

</details>

---

<details>
<summary>📋 5. Clipboard from Terminal</summary>

### Install

```bash
sudo apt install wl-clipboard
```

### Usage

```bash
echo "text" | wl-copy
wl-copy < file.txt
wl-paste
```

</details>

---

<details>
<summary>🧩 6. VS Code Settings Transfer</summary>

### Paths

```bash
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
```

### Restore

```bash
mkdir -p ~/.config/Code/User
cp settings.json ~/.config/Code/User/
cp keybindings.json ~/.config/Code/User/
```

</details>

---

<details>
<summary>🧱 7. GRUB Customization</summary>

```bash
sudo nano /etc/default/grub
sudo update-grub
```

</details>

---

<details>
<summary>🧠 8. Swap + ZRAM Strategy</summary>

* ZRAM → 100% RAM (priority 100)
* Disk swap → fallback (priority -1)

```bash
swapon --show
```

</details>

---

<details>
<summary>🧪 9. Fix Stuck Terminal</summary>

```bash
killall gnome-terminal-server
ps aux | grep terminal
```

</details>

---

<details>
<summary>🧰 10. Essential Packages</summary>

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget htop neovim xclip build-essential tlp zram-tools
```

</details>

---

<details>
<summary>🧹 11. Remove Snap</summary>

```bash
# Remove installed snap apps (optional)
snap list

# Remove snapd
sudo apt autoremove --purge snapd gnome-software-plugin-snap

# Clean leftovers
rm -rf ~/snap
sudo rm -rf /var/cache/snapd/

# Prevent reinstall
sudo apt-mark hold snapd
```

</details>

---

<details>
<summary>⌨️ 12. Bash History Scrolling</summary>

```bash
echo '
"\e[A": history-search-backward
"\e[B": history-search-forward
' >> ~/.inputrc

bind -f ~/.inputrc
```

</details>

---


<details>
<summary>🚫 13. Global Git Ignore (.vscode)</summary>

### Set global gitignore file
```bash
git config --global core.excludesfile ~/.gitignore_global
# Add .vscode to global ignore
echo ".vscode/" >> ~/.gitignore_global
```

### Verify
```bash
git config --global core.excludesfile
cat ~/.gitignore_global
```

</details>

---


<details>
<summary>🪟 14. Move Window Controls to Left (Ubuntu / GNOME)</summary>

```bash
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
```
</details>

---


<details>
<summary>🪟 15. Install GNOME Extension Manager</summary>

```bash
sudo apt install gnome-shell-extension-manager
```

Launch:
```bash
extension-manager
```

##  Install Bluetooth Battery Extension

Inside Extension Manager search for:

`Bluetooth Battery Meter`

Enable the extension.
##  Install Clipboard Manager

Inside Extension Manager search for:

`clipboard-indicator`

Enable the extension.

##  Install Fullscreen Notifications

Inside Extension Manager search for:

`Fullscreen Notifications`

Enable the extension.

Link: https://extensions.gnome.org/extension/1610/fullscreen-notifications/

This is useful when you want notifications to appear even while watching videos or using fullscreen apps.

</details>

---

<details>
<summary>🪟 16. Sticky Keys setup</summary>

# keyd One-Shot Modifier Setup (Wayland Compatible)

## Install

```bash
sudo apt install keyd
```

## Enable Service

```bash
sudo systemctl enable keyd
sudo systemctl start keyd
```

## Configure

```bash
sudo mkdir -p /etc/keyd
sudo nano /etc/keyd/default.conf
```

Paste:

```ini
[ids]

*

[global]

oneshot_timeout = 2000

[main]

leftshift = oneshot(shift)
rightshift = oneshot(shift)

leftalt = oneshot(alt)
rightalt = oneshot(alt)

leftcontrol = oneshot(control)
rightcontrol = oneshot(control)
```

## Restart keyd

```bash
sudo systemctl restart keyd
```

## Disable GNOME Sticky Keys

```bash
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
```


</details>

---

<details>
<summary><strong>17. Use VS Code as sudoedit Editor</strong></summary>

<br>

This allows editing root-owned files using your normal VS Code instance while preserving:

- Dark mode
- Extensions
- Wayland integration
- Fonts/themes/settings
- Existing VS Code session

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export EDITOR="code --wait"
export VISUAL="code --wait"
```

Reload shell:

```bash
source ~/.bashrc
```

Now safely edit privileged files using:

```bash
sudoedit /etc/keyd/default.conf
```

Unlike:

```bash
sudo code
```

or:

```bash
sudo gnome-text-editor
```

this approach:
- avoids broken themes
- avoids root GUI issues
- preserves user environment
- is the recommended Linux workflow

</details>

---

<details>
<summary><strong>18. Fix VS Code Multi-Cursor Shortcuts on Ubuntu/GNOME</strong></summary>

<br>

Ubuntu/GNOME reserves these shortcuts by default:

```text
Ctrl + Alt + Up
Ctrl + Alt + Down
```

This conflicts with VS Code multi-cursor shortcuts:
- Add Cursor Above
- Add Cursor Below

## Remove GNOME Workspace Shortcut Conflicts

Run:

```bash
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]"
```

## Verify

```bash
gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-up
gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-down
```

Expected output:

```bash
@as []
@as []
```

or:

```bash
[]
```

## Important

Logout/login after applying changes on Wayland.

## VS Code Shortcuts

After fixing conflicts:

```text
Ctrl + Alt + Up
Ctrl + Alt + Down
```

should work for:
- Add cursor above
- Add cursor below

</details>

---


<details>
<summary><strong>19. Macos like full screen move to new workspace</strong></summary>

```bash
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
```

```bash
cat << 'EOF' > ~/.local/share/gnome-shell/extensions/fullscreen-workspace@local/extension.js
import Meta from 'gi://Meta';

let signals = [];
let createdSignal = null;

function moveToNewWorkspace(win) {

    if (win._moved)
        return;

    win._moved = true;

    const manager = global.workspace_manager;

    // Create workspace
    manager.append_new_workspace(
        false,
        global.get_current_time()
    );

    const newWorkspace =
        manager.get_workspace_by_index(
            manager.n_workspaces - 1
        );

    // Move window
    win.change_workspace(newWorkspace);

    // Switch to workspace
    newWorkspace.activate_with_focus(
        win,
        global.get_current_time()
    );
}

function handleWindow(win) {

    const signal = win.connect(
        'notify::fullscreen',
        () => {

            if (win.is_fullscreen()) {
                moveToNewWorkspace(win);
            } else {
                win._moved = false;
            }
        }
    );

    signals.push([win, signal]);
}

export default class Extension {

    enable() {

        // Existing windows
        global.get_window_actors().forEach(actor => {
            handleWindow(actor.meta_window);
        });

        // New windows
        createdSignal = global.display.connect(
            'window-created',
            (_, win) => {
                handleWindow(win);
            }
        );
    }

    disable() {

        if (createdSignal)
            global.display.disconnect(createdSignal);

        signals.forEach(([win, signal]) => {
            try {
                win.disconnect(signal);
            } catch {}
        });

        signals = [];
    }
}
EOF

gnome-extensions disable fullscreen-workspace@local
gnome-extensions enable fullscreen-workspace@local

echo "Reloaded extension"
```

Logout then login

</details>


## Move windows to new ws
https://github.com/sobeitnow0/Auto-Move-to-New-Workspace

## ✅ Final Recommended Setup

* TLP enabled
* ZRAM (100%, zstd)
* ZSWAP optional
* Git via SSH
* Clipboard via xclip
* VSCode configs restored
* Dual boot time fixed

---

