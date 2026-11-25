# agy-tern enhancements for Tern

Custom plugin, UI polish, and conversation scroll patch specifically for **agy-tern** inside **Tern** on Linux.

> Note: This repository intentionally contains **only `agy-tern` customizations** (no personal Tern themes, Chrome tab keybinds, shell/Starship rules, or GNOME/Nautilus scripts), so anyone can apply it cleanly without overwriting their own Tern setup.

Repository: `https://github.com/mqqff/agy-tern`

## What's Included

- `tern/plugins/agy-paste/`
  - `window.luau`:
    - **Image clipboard paste** (`Ctrl+V` / `paste` override) in `agy-tern` using `wl-paste` (Wayland) or `xclip` (X11)
    - **Smart `Ctrl+A`** (`plugin.agy-paste.ctrl-a`) so select-all works inside `agy-tern` without breaking normal terminal `Ctrl+A`
    - **`Ctrl+Home` / `Ctrl+End` bridge** (`scroll_top` / `scroll_bottom` overrides forwarded to `agy-tern`)
  - `styles.css`:
    - `agy-tern` conversation/composer typography & layout tweaks
    - `.sf-overlay.modal` fixes so long text inputs and multi-line option buttons wrap instead of clipping
- `patches/patch-agy-tern.py`
  - Patches `agy-tern`'s `dist/ui-*.js` so `Ctrl+Home` and `Ctrl+End` scroll `main.conversation` to `"start"` and `"end"` (re-run after `agy-tern` updates)
- `install.sh`
  - Auto-installs `wl-clipboard` and `xclip` (`dnf`, `apt-get`, `pacman`, or `zypper`)
  - Installs the `agy-paste` plugin to `~/.config/tern/plugins/agy-paste/`
  - Safely merges **only** the `agy-tern` custom agent entry (`agents.custom`, `agents.own_tools`) and missing `agy-tern` keybinds (`ctrl+a`, `ctrl+home`, `ctrl+end`) into `~/.config/tern/settings.json` (creating `settings.json.bak` first; never overwrites your existing theme, opacity, or other keybinds)
  - Patches `~/.local/share/agy-tern/current/dist/ui-*.js` if present

## Install

Prerequisites:
- **Tern** and **agy-tern** installed (`python3` recommended for JSON merge & JS patch; `wl-clipboard` and `xclip` are auto-installed by `install.sh`).

```bash
git clone https://github.com/mqqff/agy-tern.git ~/Projects/agy-tern
cd ~/Projects/agy-tern
bash install.sh
```

After `install.sh`, inside Tern:
- Run **Reload settings** (`Ctrl+Shift+F5` by default)
- Open command palette (`Ctrl+Shift+P`) -> **Reload plugins**

## Keybinds Needed

`install.sh` adds these to `~/.config/tern/settings.json` if not already set:

```json
"ctrl+a": "plugin.agy-paste.ctrl-a",
"ctrl+home": "scroll_top",
"ctrl+end": "scroll_bottom"
```

## After `agy-tern` Updates

Re-run the scroll patch whenever `agy-tern` updates its JS bundle:

```bash
python3 patches/patch-agy-tern.py
```
