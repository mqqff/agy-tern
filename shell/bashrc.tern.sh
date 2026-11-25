# Default editor & Starship prompt (hanya aktif di Tern; terminal lain pakai bash bawaan)
if [ "${TERM_PROGRAM:-}" = "tern" ]; then
    export EDITOR="tern open --wait"
    export VISUAL="tern open --wait"
    if command -v starship >/dev/null 2>&1; then
        eval "$(starship init bash)"
    fi
fi
