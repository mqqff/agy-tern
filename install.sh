#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${HOME}/.config/tern/settings.json"

install_clipboard_tools() {
    if command -v wl-paste >/dev/null 2>&1 && command -v xclip >/dev/null 2>&1; then
        echo "Clipboard tools already installed (wl-paste, xclip)."
        return 0
    fi

    local sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo_cmd="sudo"
        else
            echo "Warning: sudo not found; please install wl-clipboard and xclip manually."
            return 0
        fi
    fi

    echo "Installing wl-clipboard and xclip..."
    if command -v dnf >/dev/null 2>&1; then
        if ! ${sudo_cmd} dnf install -y wl-clipboard xclip; then
            echo "Warning: failed to install wl-clipboard/xclip via dnf."
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        if ! (${sudo_cmd} apt-get update && ${sudo_cmd} apt-get install -y wl-clipboard xclip); then
            echo "Warning: failed to install wl-clipboard/xclip via apt-get."
        fi
    elif command -v pacman >/dev/null 2>&1; then
        if ! ${sudo_cmd} pacman -S --noconfirm --needed wl-clipboard xclip; then
            echo "Warning: failed to install wl-clipboard/xclip via pacman."
        fi
    elif command -v zypper >/dev/null 2>&1; then
        if ! ${sudo_cmd} zypper install -y wl-clipboard xclip; then
            echo "Warning: failed to install wl-clipboard/xclip via zypper."
        fi
    else
        echo "Warning: unsupported package manager; install wl-clipboard and xclip manually."
    fi
}

merge_tern_settings() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Warning: python3 not found; skipping automatic ~/.config/tern/settings.json merge."
        return 0
    fi

    python3 - "${SETTINGS_FILE}" <<'PY'
import json
import shutil
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
settings_path.parent.mkdir(parents=True, exist_ok=True)

if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Warning: could not parse {settings_path} as JSON ({exc}); skipping settings merge.")
        sys.exit(0)
    if not isinstance(data, dict):
        print(f"Warning: {settings_path} is not a JSON object; skipping settings merge.")
        sys.exit(0)
    original_text = settings_path.read_text(encoding="utf-8")
else:
    data = {}
    original_text = None

changed = False

agents = data.setdefault("agents", {})
if isinstance(agents, dict):
    custom = agents.setdefault("custom", [])
    if isinstance(custom, list) and not any(isinstance(item, dict) and item.get("id") == "agy-tern" for item in custom):
        custom.append({
            "id": "agy-tern",
            "name": "Antigravity Tern",
            "command": "agy-tern",
            "args": [],
            "env": {},
        })
        changed = True
    own_tools = agents.setdefault("own_tools", [])
    if isinstance(own_tools, list) and "agy-tern" not in own_tools:
        own_tools.append("agy-tern")
        changed = True

keybinds = data.setdefault("keybinds", {})
if isinstance(keybinds, dict):
    desired_keybinds = {
        "ctrl+a": "plugin.agy-paste.ctrl-a",
        "ctrl+home": "scroll_top",
        "ctrl+end": "scroll_bottom",
    }
    for key, action in desired_keybinds.items():
        if key not in keybinds:
            keybinds[key] = action
            changed = True
        elif keybinds[key] != action:
            print(f"Note: keeping existing keybind {key!r} -> {keybinds[key]!r} (expected {action!r} for agy-tern).")

if not changed:
    print(f"Tern settings already include agy-tern integration: {settings_path}")
    sys.exit(0)

if original_text is not None:
    backup_path = settings_path.with_suffix(".json.bak")
    shutil.copy2(settings_path, backup_path)
    print(f"Backed up existing settings to {backup_path}")

settings_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(f"Merged agy-tern integration into {settings_path}")
PY
}

# 1. Auto-install clipboard dependencies (wl-clipboard & xclip)
install_clipboard_tools

# 2. Install agy-paste plugin for Tern
mkdir -p "${HOME}/.config/tern/plugins/agy-paste"
cp "${REPO_DIR}/tern/plugins/agy-paste/plugin.toml" "${HOME}/.config/tern/plugins/agy-paste/plugin.toml"
cp "${REPO_DIR}/tern/plugins/agy-paste/styles.css" "${HOME}/.config/tern/plugins/agy-paste/styles.css"
cp "${REPO_DIR}/tern/plugins/agy-paste/window.luau" "${HOME}/.config/tern/plugins/agy-paste/window.luau"
echo "Installed agy-paste plugin to ${HOME}/.config/tern/plugins/agy-paste"

# 3. Merge only agy-tern agent registration and keybinds into ~/.config/tern/settings.json
merge_tern_settings

# 4. Patch agy-tern Ctrl+Home / Ctrl+End conversation scroll if installed
if [ -d "${HOME}/.local/share/agy-tern/current/dist" ]; then
    python3 "${REPO_DIR}/patches/patch-agy-tern.py" || echo "Warning: could not auto-patch agy-tern (version may differ)."
else
    echo "agy-tern dist directory not found (~/.local/share/agy-tern/current/dist); skipping JS patch."
fi

# 5. Dependency status summary
echo ""
echo "Dependency check:"
for bin in tern agy-tern python3 wl-paste xclip; do
    if command -v "${bin}" >/dev/null 2>&1 || [ -x "${HOME}/.local/bin/${bin}" ]; then
        echo "  [OK]      ${bin}"
    else
        echo "  [MISSING] ${bin}"
    fi
done

echo ""
echo "Done! Next steps:"
echo "  - In Tern: press Ctrl+Shift+F5 (Reload settings) and Ctrl+Shift+P -> Reload plugins"
