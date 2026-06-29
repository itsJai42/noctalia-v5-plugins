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
assert manifest["id"] == "noctalia/zen-note"
assert (ROOT / manifest["service"][0]["entry"]).is_file()
assert (ROOT / manifest["desktop_widget"][0]["entry"]).is_file()

settings = {item["key"] for item in manifest["setting"]}
settings.update(item["key"] for item in manifest["desktop_widget"][0]["setting"])
source = "\n".join(path.read_text() for path in ROOT.glob("*.luau"))
assert set(re.findall(r'(?:noctalia|desktopWidget)\.getConfig\("([^"]+)"\)', source)) <= settings
for key in re.findall(r'noctalia\.tr\("([^"]+)"', source):
    has_key(translations, key)

print("Zen Note manifest, entries, settings, and translations valid")
