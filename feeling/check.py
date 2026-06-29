#!/usr/bin/env python3
import json
import re
import tomllib
from pathlib import Path

ROOT = Path(__file__).parent


def has_key(data, dotted_key):
    for part in dotted_key.split("."):
        data = data[part]


manifest = tomllib.loads((ROOT / "plugin.toml").read_text())
translations = json.loads((ROOT / "translations/en.json").read_text())

assert manifest["id"] == "noctalia/feeling"
assert manifest["min_noctalia"] == "5.0.0"
for section in ("service", "desktop_widget", "widget", "panel"):
    assert (ROOT / manifest[section][0]["entry"]).is_file(), f"missing entry for {section}"

# Every declared setting key (plugin-level + desktop_widget-level)
settings = {item["key"] for item in manifest.get("setting", [])}
settings.update(item["key"] for item in manifest["desktop_widget"][0].get("setting", []))

source = "\n".join(p.read_text() for p in ROOT.glob("*.luau"))

# getConfig keys must be declared settings
used_config = set(re.findall(r'(?:noctalia|desktopWidget)\.getConfig\("([^"]+)"\)', source))
assert used_config <= settings, f"undeclared config keys: {used_config - settings}"

# tr keys must exist in translations
for key in re.findall(r'noctalia\.tr\("([^"]+)"', source):
    has_key(translations, key)

# every onClick="name" must have a matching `function name`
handlers = set(re.findall(r'onClick\s*=\s*"([^"]+)"', source))
defined = set(re.findall(r'function\s+([A-Za-z_]\w*)\s*\(', source))
builtin = {"closePanel"}  # panel.close is wrapped; allow well-known names
missing = handlers - defined - builtin
assert not missing, f"onClick handlers with no function: {missing}"

print("Feeling manifest, entries, settings, translations, and handlers valid")
