#!/usr/bin/env python3
"""Patch agy-tern bundle so Ctrl+Home / Ctrl+End scroll main.conversation."""

from pathlib import Path
import glob

TARGET = """      if (key2.name === "page_up" || key2.name === "page_down") {
        surface.scroll("main.conversation", key2.name === "page_up" ? "page-up" : "page-down");
        continue;
      }"""

PATCH = TARGET + """
      if (key2.ctrl && !key2.alt && !key2.meta && (key2.name === "home" || key2.name === "end")) {
        surface.scroll("main.conversation", key2.name === "home" ? "start" : "end");
        continue;
      }"""

dist_dir = Path.home() / ".local/share/agy-tern/current/dist"
ui_files = sorted(dist_dir.glob("ui-*.js"))
if not ui_files:
    raise SystemExit(f"No ui-*.js found under {dist_dir}")

for ui_path in ui_files:
    text = ui_path.read_text(encoding="utf-8")
    if PATCH in text:
        print(f"Already patched: {ui_path}")
        continue
    if TARGET not in text:
        raise SystemExit(f"Expected scroll block not found in {ui_path}")
    ui_path.write_text(text.replace(TARGET, PATCH, 1), encoding="utf-8")
    print(f"Patched: {ui_path}")
