#!/usr/bin/env python3
"""Patch agy-tern bundle: Ctrl+Home/Ctrl+End scroll & no duplicate command header."""

from pathlib import Path

SCROLL_TARGET = """      if (key2.name === "page_up" || key2.name === "page_down") {
        surface.scroll("main.conversation", key2.name === "page_up" ? "page-up" : "page-down");
        continue;
      }"""

SCROLL_PATCH = SCROLL_TARGET + """
      if (key2.ctrl && !key2.alt && !key2.meta && (key2.name === "home" || key2.name === "end")) {
        surface.scroll("main.conversation", key2.name === "home" ? "start" : "end");
        continue;
      }"""

TOOL_HEADER_TARGET = """      return /* @__PURE__ */ jsxDEV("tool", {
        name: summary.name,
        title: summary.title,
        target: summary.target,
        targetKind: summary.targetKind,"""

TOOL_HEADER_PATCH = """      const hideDupTarget = !collapsed && !summary.showRawInput && Boolean(summary.fullCommand);
      return /* @__PURE__ */ jsxDEV("tool", {
        name: summary.name,
        title: summary.title,
        target: hideDupTarget ? undefined : summary.target,
        targetKind: hideDupTarget ? undefined : summary.targetKind,"""

PATCHES = [
    ("Ctrl+Home/Ctrl+End scroll", SCROLL_TARGET, SCROLL_PATCH),
    ("dedupe expanded command header", TOOL_HEADER_TARGET, TOOL_HEADER_PATCH),
]

dist_dir = Path.home() / ".local/share/agy-tern/current/dist"
ui_files = sorted(dist_dir.glob("ui-*.js"))
if not ui_files:
    raise SystemExit(f"No ui-*.js found under {dist_dir}")

for ui_path in ui_files:
    text = ui_path.read_text(encoding="utf-8")
    changed = False
    for label, target, replacement in PATCHES:
        if replacement in text:
            print(f"Already patched ({label}): {ui_path}")
            continue
        if target not in text:
            raise SystemExit(f"Expected block for '{label}' not found in {ui_path}")
        text = text.replace(target, replacement, 1)
        changed = True
        print(f"Patched ({label}): {ui_path}")
    if changed:
        ui_path.write_text(text, encoding="utf-8")
