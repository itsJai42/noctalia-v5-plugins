#!/usr/bin/env python3
"""Collect hotkeys from Niri/KDL, Kitty, TOML, and JSON config files."""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import shlex
import sys
import time
from pathlib import Path
from typing import Any

try:
    import tomllib  # Python 3.11+
except Exception:  # pragma: no cover - old Python fallback is handled at runtime
    tomllib = None

STATE_PATH = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "noctalia" / "hotkeys-cheatsheet.json"

KNOWN = {
    "niri": {
        "id": "niri",
        "name": "Niri",
        "kind": "niri",
        "paths": ["~/.config/niri/config.d/70-binds.kdl", "~/.config/niri/config.kdl"],
    },
    "noctalia": {
        "id": "noctalia",
        "name": "Noctalia",
        "kind": "noctalia",
        "paths": [
            "~/.config/niri/config.d/70-binds.kdl",
            "~/.config/niri/config.kdl",
            "~/.config/noctalia/*.toml",
            "~/.local/state/noctalia/settings.toml",
        ],
    },
    "kitty": {
        "id": "kitty",
        "name": "Kitty",
        "kind": "kitty",
        "paths": ["~/.config/kitty/kitty.conf", "~/.config/kitty/*.conf", "/usr/share/doc/kitty/kitty.conf"],
    },
}
KNOWN_ORDER = ["niri", "noctalia", "kitty"]

KEY_NAMES = {
    "BackSpace", "Tab", "Return", "Enter", "Escape", "Esc", "Space", "Delete", "Insert",
    "Home", "End", "Page_Up", "Page_Down", "PageUp", "PageDown", "Left", "Right", "Up", "Down",
    "Print", "Pause", "Menu", "Caps_Lock", "Num_Lock", "Scroll_Lock", "F1", "F2", "F3", "F4",
    "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "F13", "F14", "F15", "F16", "F17",
    "F18", "F19", "F20", "F21", "F22", "F23", "F24",
}

NOCTALIA_MARKERS = (
    "shell-action", "noctalia msg", "noctalia:", "panel-toggle", "settings-toggle",
    "launcher", "control-center", "clipboard", "screenshot", "wallpaper", "session",
)


def expand(pattern: str) -> str:
    return os.path.expandvars(os.path.expanduser(str(pattern)))


def expand_paths(patterns: list[str]) -> list[str]:
    out: list[str] = []
    for pattern in patterns:
        expanded = expand(pattern)
        matches = sorted(glob.glob(expanded)) if any(c in expanded for c in "*?[") else []
        if matches:
            out.extend(matches)
        elif Path(expanded).exists():
            out.append(expanded)
    seen: set[str] = set()
    unique: list[str] = []
    for path in out:
        real = str(Path(path).expanduser())
        if real not in seen:
            seen.add(real)
            unique.append(real)
    return unique


def load_registry() -> dict[str, Any]:
    try:
        data = json.loads(STATE_PATH.read_text())
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def save_registry(data: dict[str, Any]) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def strip_comment(line: str, marker: str) -> tuple[str, str]:
    quote = ""
    escaped = False
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = ""
        elif ch in "'\"":
            quote = ch
        elif marker == "//" and line.startswith("//", i):
            return line[:i].rstrip(), line[i + 2 :].strip()
        elif marker == "#" and ch == "#":
            return line[:i].rstrip(), line[i + 1 :].strip()
        i += 1
    return line.rstrip(), ""


def clean_comment(text: str) -> str:
    text = re.sub(r"^[\s/\-─═#:]+|[\s/\-─═#]+$", "", text.strip())
    text = re.sub(r"\s+", " ", text)
    skip = ("docs:", "kdl format:", "use `wev`", "most actions", "shell actions route")
    return "" if text.lower().startswith(skip) else text


def is_heading(text: str) -> bool:
    if not text or len(text) > 72 or text.endswith("."):
        return False
    if any(token in text for token in ("=", "`", "(", ")")):
        return False
    return bool(re.search(r"[A-Za-z]", text))


def looks_like_key(token: str) -> bool:
    token = token.strip('"')
    return (
        "+" in token
        or token in KEY_NAMES
        or bool(re.match(r"^(XF86|Mouse|Wheel)", token))
        or bool(re.match(r"^F\d{1,2}$", token))
    )


def titleize(text: str) -> str:
    text = re.sub(r"[_-]+", " ", text).strip()
    return text[:1].upper() + text[1:]


def summarize_action(body: str, prefer_noctalia: bool = False) -> str:
    body = re.sub(r"\s+", " ", body).strip().rstrip(";")
    shell = re.search(r'"shell-action"\s+"([^"]+)"', body)
    if shell:
        return titleize(shell.group(1))
    msg = re.search(r"noctalia\s+msg\s+([^;]+)", body)
    if msg:
        return titleize(msg.group(1))
    if body.startswith("spawn") or body.startswith("spawn-sh"):
        parts = re.findall(r'"([^"]+)"|\S+', body)
        flat = [p if isinstance(p, str) else "" for p in parts]
        words = [w for w in flat if w and w not in {"spawn", "spawn-sh"}]
        return "Run " + (Path(words[0]).name if words else "command")
    first = body.split(";", 1)[0].strip()
    return titleize(first)


def add_item(items: list[dict[str, str]], seen: set[tuple[str, str]], keys: str, action: str, group: str, description: str, source: str) -> None:
    keys = re.sub(r"\s+", " ", keys.strip().strip('"'))
    action = re.sub(r"\s+", " ", action.strip())
    description = re.sub(r"\s+", " ", description.strip())
    if not keys or not action:
        return
    sig = (keys.lower(), action.lower())
    if sig in seen:
        return
    seen.add(sig)
    items.append({
        "keys": keys,
        "action": action,
        "group": group or "General",
        "description": description,
        "source": source,
    })


def read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(errors="replace").splitlines()
    except Exception:
        return []


def iter_kdl_sources(path: Path, visited: set[Path]) -> list[tuple[Path, list[str]]]:
    try:
        real = path.resolve()
    except Exception:
        real = path
    if real in visited or not path.exists():
        return []
    visited.add(real)
    lines = read_lines(path)
    sources = [(path, lines)]
    for line in lines:
        clean, _ = strip_comment(line, "//")
        match = re.match(r'\s*include\s+"([^"]+)"', clean)
        if match:
            child = Path(expand(match.group(1)))
            if not child.is_absolute():
                child = path.parent / child
            sources.extend(iter_kdl_sources(child, visited))
    return sources


def parse_niri(paths: list[str], noctalia_only: bool = False) -> tuple[list[dict[str, str]], list[str], str]:
    items: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    used: list[str] = []
    sources: list[tuple[Path, list[str]]] = []
    visited: set[Path] = set()
    for raw in paths:
        sources.extend(iter_kdl_sources(Path(raw), visited))
    if not sources:
        return [], [], "No readable Niri/KDL config found."

    for path, lines in sources:
        used.append(str(path))
        group = "General"
        last_comment = ""
        pending = ""
        depth = 0
        start_comment = ""
        for line in lines:
            clean, comment = strip_comment(line, "//")
            comment = clean_comment(comment)
            if comment:
                if is_heading(comment):
                    group = comment
                else:
                    last_comment = comment
            clean = clean.strip()
            if not clean:
                continue
            if pending:
                pending += " " + clean
                depth += clean.count("{") - clean.count("}")
            else:
                if "{" not in clean:
                    continue
                before_try = clean.split("{", 1)[0]
                try:
                    try_tokens = shlex.split(before_try)
                except Exception:
                    try_tokens = before_try.split()
                if not try_tokens or not looks_like_key(try_tokens[0]):
                    last_comment = ""
                    continue
                pending = clean
                start_comment = last_comment
                depth = clean.count("{") - clean.count("}")
            if depth > 0:
                continue
            before, body = pending.split("{", 1)
            body = body.rsplit("}", 1)[0]
            pending = ""
            depth = 0
            try:
                tokens = shlex.split(before)
            except Exception:
                tokens = before.split()
            body_flat = re.sub(r"\s+", " ", body).strip().rstrip(";")
            if noctalia_only and not any(marker in body_flat for marker in NOCTALIA_MARKERS):
                last_comment = ""
                continue
            summary = summarize_action(body_flat, noctalia_only)
            action = summary if ("shell-action" in body_flat or "noctalia msg" in body_flat) else (start_comment or summary)
            add_item(items, seen, tokens[0], action, group, body_flat, str(path))
            last_comment = ""
    return items, sorted(set(used)), "" if items else "No hotkeys found."


def iter_kitty_sources(path: Path, visited: set[Path]) -> list[tuple[Path, list[str]]]:
    try:
        real = path.resolve()
    except Exception:
        real = path
    if real in visited or not path.exists():
        return []
    visited.add(real)
    lines = read_lines(path)
    sources = [(path, lines)]
    for line in lines:
        clean, _ = strip_comment(line, "#")
        match = re.match(r"\s*include\s+(.+)", clean)
        if match:
            child_s = match.group(1).strip()
            if child_s:
                child = Path(expand(child_s))
                if not child.is_absolute():
                    child = path.parent / child
                sources.extend(iter_kitty_sources(child, visited))
    return sources


def parse_kitty(paths: list[str]) -> tuple[list[dict[str, str]], list[str], str]:
    items: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    group = "General"
    last_comment = ""
    used: list[str] = []
    sources: list[tuple[Path, list[str]]] = []
    visited: set[Path] = set()
    for raw in paths:
        sources.extend(iter_kitty_sources(Path(raw), visited))
    if not sources:
        return [], [], "No readable Kitty config found."
    for path, lines in sources:
        used.append(str(path))
        for line in lines:
            clean, comment_raw = strip_comment(line, "#")
            comment_text = clean_comment(comment_raw)
            clean = clean.strip()
            default_map = False
            if not clean.startswith("map ") and comment_raw.strip().startswith("map "):
                clean = comment_raw.strip()
                default_map = True
            elif comment_text:
                if is_heading(comment_text):
                    group = comment_text
                    last_comment = ""
                else:
                    last_comment = comment_text
            if not clean.startswith("map "):
                if clean:
                    last_comment = ""
                continue
            try:
                parts = shlex.split(clean)
            except Exception:
                parts = clean.split()
            key_index = 1
            while key_index < len(parts) and parts[key_index].startswith("--"):
                key_index += 1
            if len(parts) <= key_index + 1:
                continue
            keys = parts[key_index]
            action_body = " ".join(parts[key_index + 1:])
            action = titleize(action_body.split()[0]) if default_map else (last_comment or titleize(action_body.split()[0]))
            add_item(items, seen, keys, action, group, action_body, str(path))
            if default_map:
                last_comment = ""
    return items, sorted(set(used)), "" if items else "No Kitty maps found."


def first_string(obj: dict[str, Any], keys: tuple[str, ...]) -> str:
    for key in keys:
        value = obj.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def walk_struct(obj: Any, items: list[dict[str, str]], seen: set[tuple[str, str]], group: str, source: str) -> None:
    if isinstance(obj, dict):
        enabled = obj.get("enabled", True)
        keys = first_string(obj, ("keys", "key", "shortcut", "hotkey", "bind", "binding", "accelerator"))
        action = first_string(obj, ("action", "title", "name", "command", "description", "label", "type"))
        desc = first_string(obj, ("description", "command", "action"))
        new_group = first_string(obj, ("group", "section", "category")) or group
        if keys and action and enabled is not False:
            add_item(items, seen, keys, action, new_group, desc, source)
        for value in obj.values():
            if isinstance(value, (dict, list)):
                walk_struct(value, items, seen, new_group, source)
    elif isinstance(obj, list):
        for value in obj:
            walk_struct(value, items, seen, group, source)


def parse_toml(paths: list[str]) -> tuple[list[dict[str, str]], list[str], str]:
    if tomllib is None:
        return [], [], "Python 3.11+ required for TOML parsing."
    items: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    used: list[str] = []
    for raw in paths:
        path = Path(raw)
        try:
            data = tomllib.loads(path.read_text(errors="replace"))
        except Exception as exc:
            continue
        used.append(str(path))
        walk_struct(data, items, seen, "General", str(path))
    return items, sorted(set(used)), "" if items else "No TOML shortcuts found. Expected [[hotkey]] keys/action entries."


def parse_json_file(paths: list[str]) -> tuple[list[dict[str, str]], list[str], str]:
    items: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    used: list[str] = []
    for raw in paths:
        path = Path(raw)
        try:
            data = json.loads(path.read_text(errors="replace"))
        except Exception:
            continue
        used.append(str(path))
        walk_struct(data, items, seen, "General", str(path))
    return items, sorted(set(used)), "" if items else "No JSON shortcuts found. Expected keys/action entries."


def parse_generic_kdl(paths: list[str]) -> tuple[list[dict[str, str]], list[str], str]:
    items, used, error = parse_niri(paths, False)
    seen = {(item["keys"].lower(), item["action"].lower()) for item in items}
    for raw in paths:
        path = Path(raw)
        if not path.exists():
            continue
        if str(path) not in used:
            used.append(str(path))
        group = "General"
        for line in read_lines(path):
            clean, comment = strip_comment(line, "//")
            comment = clean_comment(comment)
            if comment and is_heading(comment):
                group = comment
            match = re.search(r'(?:hotkey|shortcut)\s+"?([^"{]+?)"?\s+(?:action=)?"?([^"{]+?)"?\s*$', clean.strip())
            if match:
                add_item(items, seen, match.group(1), match.group(2), group, "", str(path))
    return items, sorted(set(used)), "" if items else error


def detect_kind(paths: list[str], requested: str) -> str:
    if requested and requested != "auto":
        return requested
    first = paths[0].lower() if paths else ""
    if first.endswith(".json"):
        return "json"
    if first.endswith(".toml"):
        return "toml"
    if "kitty" in first and first.endswith(".conf"):
        return "kitty"
    if first.endswith(".kdl"):
        return "kdl"
    return "toml"


def pin_id(source_id: str, item: dict[str, str]) -> str:
    raw = "\0".join([source_id, item.get("keys", ""), item.get("action", ""), item.get("group", "")])
    return hashlib.sha1(raw.encode()).hexdigest()[:16]


def apply_pins(source: dict[str, Any], items: list[dict[str, str]], registry: dict[str, Any]) -> None:
    pins_by_set = registry.get("pins") if isinstance(registry.get("pins"), dict) else {}
    pinned = set(pins_by_set.get(str(source.get("id", "")), []))
    for item in items:
        item_id = pin_id(str(source.get("id", "")), item)
        item["pin_id"] = item_id
        if item_id in pinned:
            item["pinned"] = True


def parse_source(source: dict[str, Any], registry: dict[str, Any]) -> dict[str, Any]:
    paths = expand_paths([str(p) for p in source.get("paths", [])])
    requested = str(source.get("kind", "auto"))
    kind = detect_kind(paths, requested)
    if not source.get("enabled", True):
        return {**source, "enabled": False, "kind": kind, "paths": paths, "items": [], "count": 0, "error": "Disabled"}
    if kind == "niri":
        items, used, error = parse_niri(paths, False)
    elif kind == "noctalia":
        items, used, error = parse_niri(paths, True)
    elif kind == "kitty":
        items, used, error = parse_kitty(paths)
    elif kind == "json":
        items, used, error = parse_json_file(paths)
    elif kind == "kdl":
        items, used, error = parse_generic_kdl(paths)
    else:
        items, used, error = parse_toml(paths)
    apply_pins(source, items, registry)
    return {
        **source,
        "enabled": True,
        "kind": kind,
        "paths": used or paths,
        "items": items,
        "count": len(items),
        "pinned_count": len([item for item in items if item.get("pinned")]),
        "error": error,
    }


def build_dump() -> dict[str, Any]:
    registry = load_registry()
    disabled = registry.get("disabled") if isinstance(registry.get("disabled"), dict) else {}
    sets: list[dict[str, Any]] = []
    for source_id in KNOWN_ORDER:
        source = dict(KNOWN[source_id])
        source["enabled"] = not bool(disabled.get(source_id))
        sets.append(parse_source(source, registry))
    custom = registry.get("custom") if isinstance(registry.get("custom"), list) else []
    for source in custom:
        if isinstance(source, dict):
            clean = {
                "id": str(source.get("id", "")),
                "name": str(source.get("name", "Custom")),
                "kind": str(source.get("kind", "auto")),
                "paths": [str(p) for p in source.get("paths", [])],
                "enabled": bool(source.get("enabled", True)),
                "custom": True,
            }
            if clean["id"] and clean["paths"]:
                sets.append(parse_source(clean, registry))
    selected = str(registry.get("selected", ""))
    ids = {s["id"] for s in sets}
    enabled_ids = [s["id"] for s in sets if s.get("enabled")]
    if selected not in ids or (selected not in enabled_ids and enabled_ids):
        selected = enabled_ids[0] if enabled_ids else (sets[0]["id"] if sets else "")
    return {"selected": selected, "sets": sets, "updated_at": int(time.time())}


def slug(name: str, path: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") or "custom"
    suffix = hashlib.sha1(path.encode()).hexdigest()[:8]
    return f"custom-{base}-{suffix}"


def cmd_toggle(source_id: str) -> None:
    registry = load_registry()
    disabled = registry.setdefault("disabled", {})
    if source_id in KNOWN:
        disabled[source_id] = not bool(disabled.get(source_id))
    else:
        custom = registry.get("custom") if isinstance(registry.get("custom"), list) else []
        for source in custom:
            if isinstance(source, dict) and source.get("id") == source_id:
                source["enabled"] = not bool(source.get("enabled", True))
                break
    save_registry(registry)


def cmd_select(source_id: str) -> None:
    registry = load_registry()
    registry["selected"] = source_id
    save_registry(registry)


def cmd_add(name: str, kind: str, path: str) -> None:
    registry = load_registry()
    custom = registry.setdefault("custom", [])
    source_id = slug(name, path)
    entry = {"id": source_id, "name": name, "kind": kind or "auto", "paths": [path], "enabled": True, "custom": True}
    for index, source in enumerate(custom):
        if isinstance(source, dict) and source.get("id") == source_id:
            custom[index] = entry
            break
    else:
        custom.append(entry)
    registry["selected"] = source_id
    save_registry(registry)


def cmd_remove(source_id: str) -> None:
    registry = load_registry()
    custom = registry.get("custom") if isinstance(registry.get("custom"), list) else []
    registry["custom"] = [source for source in custom if not (isinstance(source, dict) and source.get("id") == source_id)]
    pins = registry.get("pins") if isinstance(registry.get("pins"), dict) else {}
    pins.pop(source_id, None)
    registry["pins"] = pins
    if registry.get("selected") == source_id:
        registry["selected"] = "niri"
    save_registry(registry)


def cmd_pin(source_id: str, item_id: str) -> None:
    registry = load_registry()
    pins = registry.setdefault("pins", {})
    values = pins.get(source_id, [])
    if not isinstance(values, list):
        values = []
    if item_id in values:
        values = [value for value in values if value != item_id]
    else:
        values.append(item_id)
    pins[source_id] = values
    save_registry(registry)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("dump")
    p_toggle = sub.add_parser("toggle")
    p_toggle.add_argument("id")
    p_select = sub.add_parser("select")
    p_select.add_argument("id")
    p_remove = sub.add_parser("remove")
    p_remove.add_argument("id")
    p_add = sub.add_parser("add")
    p_add.add_argument("--name", required=True)
    p_add.add_argument("--kind", default="auto", choices=("auto", "niri", "noctalia", "kitty", "toml", "json", "kdl"))
    p_add.add_argument("--path", required=True)
    p_pin = sub.add_parser("pin")
    p_pin.add_argument("--set", required=True)
    p_pin.add_argument("--pin", required=True)
    args = parser.parse_args()

    if args.command == "dump":
        print(json.dumps(build_dump(), ensure_ascii=False))
    elif args.command == "toggle":
        cmd_toggle(args.id)
    elif args.command == "select":
        cmd_select(args.id)
    elif args.command == "remove":
        cmd_remove(args.id)
    elif args.command == "add":
        cmd_add(args.name.strip(), args.kind, args.path.strip())
    elif args.command == "pin":
        cmd_pin(args.set.strip(), args.pin.strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
