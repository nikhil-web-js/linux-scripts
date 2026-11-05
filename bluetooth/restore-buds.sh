#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="/usr/local/bin/buds-toggle.py"
SUDOERS_PATH="/etc/sudoers.d/buds-toggle"
USERNAME="$(id -un)"
BASHRC="$HOME/.bashrc"

echo "Installing OPPO Enco Buds play/pause fix..."
sudo apt update
sudo apt install -y python3-evdev

sudo tee "$SCRIPT_PATH" > /dev/null <<'PYTHON'
#!/usr/bin/env python3
import time
import evdev
from evdev import UInput, ecodes as e

DEVICE_NAME = "Enco Buds3 Pro"
WATCHED_KEYS = (e.KEY_PLAYCD, e.KEY_PAUSECD, e.KEY_PLAYPAUSE)
ui = UInput({e.EV_KEY: [e.KEY_PLAYPAUSE]}, name="buds-toggle")

def find_device():
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            if DEVICE_NAME in dev.name:
                return dev
            dev.close()
        except OSError:
            continue
    return None

try:
    while True:
        dev = find_device()
        if dev is None:
            time.sleep(2)
            continue
        try:
            dev.grab()
            print(f"Monitoring {dev.name}. Press Ctrl+C to stop.", flush=True)
            for event in dev.read_loop():
                if event.type == e.EV_KEY and event.code in WATCHED_KEYS and event.value == 1:
                    ui.write(e.EV_KEY, e.KEY_PLAYPAUSE, 1)
                    ui.write(e.EV_KEY, e.KEY_PLAYPAUSE, 0)
                    ui.syn()
        except OSError:
            time.sleep(2)
        finally:
            try:
                dev.ungrab()
            except OSError:
                pass
            dev.close()
except KeyboardInterrupt:
    pass
finally:
    ui.close()
PYTHON

sudo chown root:root "$SCRIPT_PATH"
sudo chmod 755 "$SCRIPT_PATH"

tmp_sudoers="$(mktemp)"
trap 'rm -f "$tmp_sudoers"' EXIT
printf '%s ALL=(root) NOPASSWD: %s\n' "$USERNAME" "$SCRIPT_PATH" > "$tmp_sudoers"
sudo visudo -cf "$tmp_sudoers"
sudo install -o root -g root -m 0440 "$tmp_sudoers" "$SUDOERS_PATH"

if ! grep -qF "alias buds=" "$BASHRC"; then
    printf "\n# OPPO Enco Buds play/pause fix\nalias buds='sudo %s'\n" "$SCRIPT_PATH" >> "$BASHRC"
fi

echo
echo "Installation complete."
echo "Run: source ~/.bashrc && buds"
echo "Stop with Ctrl+C."
