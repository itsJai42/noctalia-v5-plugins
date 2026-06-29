#!/usr/bin/env python3
"""Validate the Noctalia v5 ports without third-party Python dependencies."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGINS = {
    "air-quality", "arch-updater", "claude-code-panel", "giphy-search",
    "git-companion", "ip-monitor", "model-usage", "niri-animation-picker",
    "niri-auto-tile", "niri-layout-indicator", "niri-overview-launcher",
    "niri-screensaver", "niri-urgent-on-notification", "niri-workspaces",
    "noctalia-calculator", "obs-control", "obsidian-provider",
    "parallax-wallpaper", "plugin-manager", "protonvpn", "shell-profiles",
    "steam-price-watcher", "sticky-notes", "tailscale", "wallcards",
    "web-search",
}
ENTRY_TYPES = ("widget", "panel", "shortcut", "desktop_widget", "launcher_provider", "service")


def has_key(data: dict, dotted_key: str) -> bool:
    current = data
    for part in dotted_key.split("."):
        if not isinstance(current, dict) or part not in current:
            return False
        current = current[part]
    return True


def main() -> int:
    errors: list[str] = []
    manifests: dict[str, dict] = {}
    scripts: list[Path] = []

    for name in sorted(PLUGINS):
        directory = ROOT / name
        manifest_path = directory / "plugin.toml"
        translation_path = directory / "translations" / "en.json"
        try:
            manifest = tomllib.loads(manifest_path.read_text())
            translations = json.loads(translation_path.read_text())
        except (OSError, ValueError) as error:
            errors.append(f"{name}: {error}")
            continue

        expected_id = f"noctalia/{name}"
        if manifest.get("id") != expected_id:
            errors.append(f"{manifest_path}: id must be {expected_id}")
        manifests[expected_id] = manifest

        setting_keys = {setting["key"] for setting in manifest.get("setting", [])}
        entry_count = 0
        for entry_type in ENTRY_TYPES:
            for entry in manifest.get(entry_type, []):
                entry_count += 1
                entry_path = directory / entry.get("entry", "")
                if not entry_path.is_file():
                    errors.append(f"{manifest_path}: missing entry {entry_path.name}")
                else:
                    scripts.append(entry_path)
                setting_keys.update(setting["key"] for setting in entry.get("setting", []))
        if entry_count == 0:
            errors.append(f"{manifest_path}: no entries")

        for legacy_pattern in ("*.qml", "*.js", "manifest.json"):
            for legacy in directory.rglob(legacy_pattern):
                errors.append(f"{legacy}: legacy runtime file remains")

        for script in directory.glob("*.luau"):
            source = script.read_text()
            if re.search(r"\b(console\.|pluginApi\b|Quickshell\b|Qt\.)", source):
                errors.append(f"{script}: legacy API reference")
            for key in re.findall(r'noctalia\.tr\("([^"]+)"', source):
                if not has_key(translations, key):
                    errors.append(f"{script}: missing translation {key}")
            for key in re.findall(
                r'(?:noctalia|barWidget|panel|launcher|desktopWidget)\.getConfig\("([^"]+)"\)',
                source,
            ):
                if key not in setting_keys:
                    errors.append(f"{script}: undeclared setting {key}")

    try:
        catalog = tomllib.loads((ROOT / "catalog.toml").read_text())["plugin"]
        if {plugin["id"] for plugin in catalog} != set(manifests):
            errors.append("catalog.toml ids do not match the ported plugins")
    except (OSError, ValueError, KeyError) as error:
        errors.append(f"catalog.toml: {error}")

    compiler = shutil.which("luau-compile")
    if compiler:
        for script in sorted(set(scripts)):
            result = subprocess.run([compiler, str(script)], capture_output=True, text=True)
            if result.returncode:
                errors.append(f"{script}: {result.stderr.strip()}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Validated {len(manifests)} Noctalia v5 plugin ports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
