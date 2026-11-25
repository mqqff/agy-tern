# agy-tern config

Custom configuration bundle for **Tern**, **agy-tern**, shell prompt scoping, and optional **GNOME / Nautilus** integration on Linux.

Repository: `https://github.com/mqqff/agy-tern`

## Contents

- `tern/settings.json`
  - Chrome-style tab & window keybinds (`Ctrl+T`, `Ctrl+W`, `Ctrl+Shift+T`, `Ctrl+N`, `Ctrl+Tab`/`Ctrl+Shift+Tab`, `Ctrl+PageUp`/`Ctrl+PageDown`, `Ctrl+1`..`Ctrl+9`, `Ctrl+F`, `Ctrl+=`/`Ctrl+-`/`Ctrl+0`)
  - Terminal & chat scrollback shortcuts (`Ctrl+Home`/`Ctrl+End`, `Shift+Home`/`Shift+End`, `Shift+PageUp`/`Shift+PageDown`)
  - Preserves `Ctrl+Shift+A` for `new_agent_block` and `Ctrl+A` for `plugin.agy-paste.ctrl-a`
  - Opacity set to `100`, `dark-abyss` dark theme
- `tern/plugins/agy-paste/`
  - `window.luau`: Clipboard image paste in `agy-tern`, smart `Ctrl+A`, top-right toast positioning (`tern.css("toast-top-right", ...)`), and `scroll_top`/`scroll_bottom` overrides forwarding `Ctrl+Home`/`Ctrl+End` to `agy-tern`
  - `styles.css`: `agy-tern` conversation/composer typography & modal `.sf-overlay.modal` wrapping fixes for `.sf-input` and multi-line option buttons
- `shell/bashrc.tern.sh`
  - Scopes `EDITOR`/`VISUAL` (`tern open --wait`) and `starship init bash` to `TERM_PROGRAM="tern"` so regular terminals keep their default bash prompt and editor
- `nautilus/` *(auto-installed only if `nautilus` / GNOME is present)*
  - `scripts/Open in Tern`: Nautilus script opening Tern in `NAUTILUS_SCRIPT_CURRENT_URI`
  - `scripts-accels`: `<Control>period Open in Tern`
  - `xdg-terminals.list`: Default fallback (`org.gnome.Ptyxis.desktop`; `install.sh` auto-detects Ptyxis or GNOME Terminal)
- `patches/patch-agy-tern.py`
  - Adds `Ctrl+Home` / `Ctrl+End` (`surface.scroll("main.conversation", "start" | "end")`) to `agy-tern`'s `dist/ui-*.js` (re-run after `agy-tern update`)

## Install / Restore on a New Device

Prerequisites installed separately:
- **Tern**, **agy-tern** (and `tern acp codex` if using `agent_command: "tern acp codex"`), **starship** (optional).
- `wl-clipboard` and `xclip` are auto-installed by `install.sh` (`dnf`, `apt-get`, `pacman`, or `zypper`).

Then run:

```bash
git clone https://github.com/mqqff/agy-tern.git ~/Projects/tern-agy-config
cd ~/Projects/tern-agy-config
bash install.sh
```

What `install.sh` does automatically:
1. Auto-installs `wl-clipboard` and `xclip` if missing.
2. Installs `tern/settings.json` and the `agy-paste` plugin.
3. Copies `shell/bashrc.tern.sh` to `~/.config/tern/bashrc.tern.sh` and sources it from `~/.bashrc` (if not already present).
4. **Only on GNOME**: sets `xdg-terminals.list` and `gnome-xdg-terminals.list` to `Ptyxis` or `GNOME Terminal`.
5. **Only if `nautilus` is installed**: installs `Open in Tern` script and `scripts-accels` (`Ctrl+.`).
6. Patches `agy-tern` (`Ctrl+Home` / `Ctrl+End`) if installed.
