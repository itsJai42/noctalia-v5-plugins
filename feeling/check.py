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

# --- service logic mirror (keep in sync with service.luau parseCsv/buildState) ---
import datetime

def py_parse(text):
    m = {}
    for line in text.splitlines():
        mt = re.match(r"^(\d{4}-\d{2}-\d{2}),(\d+)$", line)
        if mt:
            m[mt.group(1)] = int(mt.group(2))
    return m

def py_week(m, today):
    return [m.get((today - datetime.timedelta(days=i)).isoformat()) for i in range(6, -1, -1)]

today = datetime.date(2026, 6, 28)
csv = "date,feeling\n2026-06-28,7\n2026-06-27,3\n2026-06-25,9\nbad,row\n"
parsed = py_parse(csv)
assert parsed == {"2026-06-28": 7, "2026-06-27": 3, "2026-06-25": 9}, parsed
assert parsed.get("2026-06-28") == 7  # today
assert py_week(parsed, today) == [None, None, None, 9, None, 3, 7], py_week(parsed, today)  # last 7d: 22..28

print("Feeling manifest, entries, settings, translations, and handlers valid")
