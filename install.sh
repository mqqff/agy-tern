#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_gnome() {
    local desktop="${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}:${DESKTOP_SESSION:-}"
    case "${desktop,,}" in
        *gnome*) return 0 ;;
    esac
    command -v gnome-shell >/dev/null 2>&1
}

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

# 1. Auto-install clipboard dependencies (wl-clipboard & xclip)
install_clipboard_tools

# 2. Tern settings & agy-paste plugin (always applied)
mkdir -p "${HOME}/.config/tern/plugins/agy-paste"
cp "${REPO_DIR}/tern/settings.json" "${HOME}/.config/tern/settings.json"
cp "${REPO_DIR}/tern/plugins/agy-paste/plugin.toml" "${HOME}/.config/tern/plugins/agy-paste/plugin.toml"
cp "${REPO_DIR}/tern/plugins/agy-paste/styles.css" "${HOME}/.config/tern/plugins/agy-paste/styles.css"
cp "${REPO_DIR}/tern/plugins/agy-paste/window.luau" "${HOME}/.config/tern/plugins/agy-paste/window.luau"

# 3. Shell snippet (copied to ~/.config/tern so ~/.bashrc stays valid even if repo moves)
cp "${REPO_DIR}/shell/bashrc.tern.sh" "${HOME}/.config/tern/bashrc.tern.sh"
BASHRC="${HOME}/.bashrc"
SOURCE_LINE='[ -f "$HOME/.config/tern/bashrc.tern.sh" ] && . "$HOME/.config/tern/bashrc.tern.sh"'
if [ -f "${BASHRC}" ] && ! grep -qF "bashrc.tern.sh" "${BASHRC}" && ! grep -qF 'if [ "${TERM_PROGRAM:-}" = "tern" ]; then' "${BASHRC}"; then
    printf '\n# Tern-scoped editor & Starship prompt\n%s\n' "${SOURCE_LINE}" >> "${BASHRC}"
    echo "Added bashrc.tern.sh source line to ~/.bashrc"
fi

# 4. GNOME-only terminal defaults (skip if not on GNOME)
if is_gnome; then
    mkdir -p "${HOME}/.config"
    TERM_DESKTOP=""
    if [ -f /usr/share/applications/org.gnome.Ptyxis.desktop ]; then
        TERM_DESKTOP="org.gnome.Ptyxis.desktop"
    elif [ -f /usr/share/applications/org.gnome.Terminal.desktop ]; then
        TERM_DESKTOP="org.gnome.Terminal.desktop"
    fi
    if [ -n "${TERM_DESKTOP}" ]; then
        printf '%s\n' "${TERM_DESKTOP}" > "${HOME}/.config/xdg-terminals.list"
        printf '%s\n' "${TERM_DESKTOP}" > "${HOME}/.config/gnome-xdg-terminals.list"
        echo "GNOME detected: set default terminal list to ${TERM_DESKTOP}"
    else
        echo "GNOME detected, but neither Ptyxis nor GNOME Terminal .desktop found; skipping xdg-terminals.list."
    fi
else
    echo "Non-GNOME environment detected: skipping GNOME xdg-terminals.list config."
fi

# 5. Nautilus-only script & Ctrl+. shortcut (skip if Nautilus is not installed)
if command -v nautilus >/dev/null 2>&1; then
    mkdir -p "${HOME}/.config/nautilus"
    mkdir -p "${HOME}/.local/share/nautilus/scripts"
    cp "${REPO_DIR}/nautilus/scripts/Open in Tern" "${HOME}/.local/share/nautilus/scripts/Open in Tern"
    chmod +x "${HOME}/.local/share/nautilus/scripts/Open in Tern"
    cp "${REPO_DIR}/nautilus/scripts-accels" "${HOME}/.config/nautilus/scripts-accels"
    echo "Nautilus detected: installed 'Open in Tern' script and Ctrl+. shortcut."
else
    echo "Nautilus not found: skipping Nautilus script and scripts-accels."
fi

# 6. Patch agy-tern Ctrl+Home / Ctrl+End conversation scroll if installed
if [ -d "${HOME}/.local/share/agy-tern/current/dist" ]; then
    python3 "${REPO_DIR}/patches/patch-agy-tern.py" || echo "Warning: could not auto-patch agy-tern (version may differ)."
fi

# 7. Dependency status summary
echo ""
echo "Dependency check:"
for bin in tern agy-tern starship python3 wl-paste xclip; do
    if command -v "${bin}" >/dev/null 2>&1 || [ -x "${HOME}/.local/bin/${bin}" ]; then
        echo "  [OK]      ${bin}"
    else
        echo "  [MISSING] ${bin}"
    fi
done

echo ""
echo "Done! Next steps:"
echo "  - In Tern: press Ctrl+Shift+F5 (Reload settings) and Ctrl+Shift+P -> Reload plugins"
if command -v nautilus >/dev/null 2>&1; then
    echo "  - In Nautilus: run 'nautilus -q' once if Nautilus is already running"
fi
echo "  - In shell: open a new terminal tab to pick up ~/.bashrc changes"
