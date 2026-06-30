# Hotkeys Cheatsheet

Noctalia v5 Luau bar widget, desktop widget, panel, and service for live hotkey cheatsheets.

## Features

- Bar widget opens a searchable cheatsheet panel.
- Desktop card shows the selected set at a glance.
- Built-in live sources:
  - Niri: `~/.config/niri/config.d/70-binds.kdl`, `~/.config/niri/config.kdl`
  - Noctalia: compositor binds that call `shell-action` / `noctalia msg`
  - Kitty: `~/.config/kitty/kitty.conf`
- Custom imports from TOML, JSON, KDL, or Kitty-style config files.
- Pin hotkeys into a top **Pinned** section shown in both panel and desktop widget.
- Enable/disable sets from the panel.

## Custom source format

Panel input accepts:

```text
Path
Name|Path
Name|format|Path
```

Formats: `auto`, `toml`, `json`, `kdl`, `kitty`.

TOML example:

```toml
[[hotkey]]
keys = "Ctrl+K"
action = "Open command palette"
group = "General"
description = "Example shortcut"
```

JSON example:

```json
[
  { "keys": "Ctrl+K", "action": "Open command palette", "group": "General" }
]
```

Custom source state is stored at `$XDG_STATE_HOME/noctalia/hotkeys-cheatsheet.json`.

## Controls

- Left click bar widget: open panel
- Middle click bar widget: cycle enabled sets
- Right click bar widget: refresh
- Desktop card arrows: cycle enabled sets

## Dependency

Requires `python3`; TOML parsing uses Python 3.11+ `tomllib`.
