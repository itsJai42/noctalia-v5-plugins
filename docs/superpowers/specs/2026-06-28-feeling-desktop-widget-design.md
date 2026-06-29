# Feeling — Noctalia v5 Desktop Widget Design

## Overview

A cozy, themable Noctalia v5 plugin that acts as a frontend for the
[`feeling`](https://github.com/qiz-li/feeling) terminal mood tracker. It lets
you glance at your recent mood and log today's feeling (1–10) with one click,
without opening a terminal. Aesthetic goal: comfy and warm, but driven entirely
by Noctalia's global theme tokens so it adapts to any palette.

Modeled on the existing `zen-note` plugin (service + desktop widget), extended
with a bar widget + panel.

## Goals

- Glanceable: today's mood and the last 7 days at a glance.
- Actionable: log/overwrite today's mood in one click from the desktop or bar.
- Themable: all colors come from theme tokens; no hardcoded hex.
- Faithful: mood→color buckets mirror the CLI exactly.
- Self-contained: reads/writes only through the `feeling` binary (no direct CSV writes).

## Non-Goals

- No editing of arbitrary past dates (today only from the UI). Past data stays
  the terminal's job (`feeling N -d DATE`).
- No charts/graphs beyond the week strip. `feeling year` stays in the terminal.
- No data migration or storage logic — the `feeling` binary owns the CSV
  (atomic writes, locking, backups already exist).

## Architecture

Four Luau entries sharing one source of truth via `noctalia.state`:

```
service.luau   headless: runs `feeling export`, parses CSV,
               publishes  state["feeling"] = { today, week[7], dates[7], error }
desktop.luau   cozy card: greeting · today · 10-dot logger · week strip
bar.luau       bar glyph tinted by today's mood; click toggles the panel
panel.luau     compact 10-dot logger (same log action as the card)
```

All read surfaces (`desktop`, `panel`, `bar`) call
`noctalia.state.watch("feeling", render)` and re-render on change. The service
is the only thing that runs the binary.

### Data flow

**Read** — service runs `feeling export` (clean CSV: `date,feeling`) on an
interval (~5 min) and once on start. It parses, derives `today` (entry whose
date == today, else nil) and the last 7 calendar days, then
`noctalia.state.set("feeling", {...})`.

**Write** — clicking dot _N_ on any surface:
1. surface calls `noctalia.state.set("feeling-log-request", { value = N, at = os.clock() })`
2. service watches that key → runs `feeling <N> -y` via `noctalia.runAsync`
   (the global `-y/--yes` flag skips the overwrite confirmation prompt — the
   CLI is otherwise interactive and would block in a non-TTY context)
3. on `exitCode == 0`, service immediately re-runs `feeling export` → re-publishes state
4. all surfaces re-render with the new value.

This is "interval + on-write": fresh after your own edits, and still picks up
terminal-side edits within the interval.

### Mood → color buckets (mirror `src/display/mod.rs`)

| Feeling | CLI color  | Theme token used        |
|---------|------------|-------------------------|
| 7–10    | DarkGreen  | `primary`               |
| 4–6     | DarkYellow | `secondary` (warm/amber)|
| 1–3     | DarkRed    | `error`                 |
| none/0  | DarkGrey   | `outline`               |

Using theme tokens (not literal green/yellow/red) keeps it themable; the
buckets preserve the CLI's good/okay/bad semantics. `secondary` is the closest
warm accent in the Noctalia palette for the "okay" band.

## Components

### `plugin.toml`

```toml
id = "noctalia/feeling"
name = "Feeling"
version = "1.0.0"
min_noctalia = "5.0.0"
author = "Jai"
license = "MIT"
dependencies = []           # feeling binary is a soft dep, handled at runtime
tags = ["desktop", "panel", "productivity", "health"]
icon = "mood-smile"
description = "A cozy mood tracker desktop widget — log today's feeling and see your week, themed to match."

# Plugin-level settings
[[setting]]
key = "binary_path"
type = "string"
default = "feeling"         # on PATH; override for a custom build
label_key = "settings.binary_path"
description_key = "settings.binary_path_description"

[[setting]]
key = "refresh_minutes"
type = "int"
default = 5
min = 1
max = 120
step = 1
label_key = "settings.refresh"
description_key = "settings.refresh_description"

[[service]]
id = "feeling-service"
entry = "service.luau"

[[desktop_widget]]
id = "feeling-card"
entry = "desktop.luau"

  [[desktop_widget.setting]]
  key = "card_width"
  type = "int"
  default = 320
  min = 260
  max = 560
  step = 20
  label_key = "settings.card_width"

  [[desktop_widget.setting]]
  key = "card_height"
  type = "int"
  default = 240
  min = 180
  max = 480
  step = 20
  label_key = "settings.card_height"

  [[desktop_widget.setting]]
  key = "show_week_strip"
  type = "bool"
  default = true
  label_key = "settings.show_week_strip"

  [[desktop_widget.setting]]
  key = "accent_by_mood"
  type = "bool"
  default = true
  label_key = "settings.accent_by_mood"
  description_key = "settings.accent_by_mood_description"

[[widget]]
id = "feeling-bar"
entry = "bar.luau"

[[panel]]
id = "feeling-panel"
entry = "panel.luau"
width = 320
height = 200
placement = "floating"
position = "center"
```

### `service.luau`

- Reads config: `binary_path`, `refresh_minutes`.
- `run(cmd, cb)` wrapper around `noctalia.runAsync` prefixing `binary_path`.
- `readState()`: `feeling export` → parse CSV (skip header, split on `,`),
  build a date→value map, derive `today` (key == `os.date("%Y-%m-%d")`), and
  `week` = last 7 days oldest→newest with values or nil. Publish via
  `noctalia.state.set("feeling", {...})`.
- On nonzero exit / missing binary: publish `{ error = tr("no_binary") }`.
- `setUpdateInterval(refresh_minutes * 60000)`; `update()` → `readState()`.
- `noctalia.state.watch("feeling-log-request", ...)`: debounce by `at`, run
  `feeling <value> -y`, then `readState()` on success.

### `desktop.luau` — the card

`desktopWidget.render(ui.column({ width, height, padding=20, gap=10,
fill="surface", border = accentColor, borderWidth=1, radius=22, align="stretch" }, {...}))`

Children:
1. Header `ui.row`: `ui.glyph({name="mood-smile", color="primary"})` +
   `ui.label` greeting (text varies by today: unset → "How are you?", good →
   "Lovely.", okay → "Hanging in there.", bad → "Be gentle with yourself.").
2. Today `ui.row`: big `ui.glyph` dot in bucket color + `ui.label` value
   ("7") + muted word ("good"). If unset: muted "not logged yet".
3. `ui.separator`.
4. Logger: `ui.row` of 10 `ui.button`s (glyph dots), variant `ghost`,
   `onClick="log1".."log10"`; filled/colored up to current value, hollow above.
   Tiny `1`/`10` end labels.
5. `ui.separator` + week strip (when `show_week_strip`): a `ui.row` of weekday
   letters above a `ui.row` of 7 dots in bucket colors (hollow `outline` for
   missing days), today's dot ringed.
6. If `error`: `ui.label({color="error"})` with a gentle install hint.

`accentColor` = today's bucket token when `accent_by_mood`, else `outline`.

Log handlers: `function log1() request(1) end` … `log10`, where
`request(n) = noctalia.state.set("feeling-log-request", {value=n, at=os.clock()})`.

### `bar.luau`

```lua
function update()
  local s = noctalia.state.get("feeling")
  barWidget.setGlyph("mood-smile")
  barWidget.setGlyphColor(bucketToken(s and s.today))
end
function onClick() noctalia.togglePanel("noctalia/feeling:feeling-panel") end
noctalia.state.watch("feeling", update)
```

### `panel.luau`

Compact version of the card: title row + close button, today line, the same
10-dot logger row. No week strip. Reuses the same `feeling-log-request`
mechanism. `panel.render(...)`, watches `feeling`.

### `translations/en.json`

Keys: `title`, greetings (`greet_unset`/`greet_good`/`greet_okay`/`greet_bad`),
`words.good`/`okay`/`bad`, `not_logged`, `no_binary`, and all `settings.*`
label/description keys referenced above.

## Files

```
feeling/
  plugin.toml
  service.luau
  desktop.luau
  bar.luau
  panel.luau
  translations/en.json
  README.md
```

Location: `~/projects/noctalia-v5-plugins/feeling/` (already a configured path
source — enable from Settings → Plugins after creation).

## Error Handling

- **Binary missing / not on PATH**: nonzero exit → state `error`; card shows a
  one-line "Install `feeling` or set its path in settings." All surfaces stay
  rendered, no crash.
- **Empty CSV / no entries**: `today` nil, week all hollow, greeting prompts to log.
- **Log fails** (nonzero exit): keep last good state, surface `error` line
  briefly; do not optimistically update the dots (state only updates after a
  successful re-read).
- **Malformed CSV row**: skip the row, continue parsing.
- **Date math**: derive today and the 7-day window from `os.date`/`os.time` in
  local time, matching how the CLI stamps dates.

## Testing

- `service.luau` CSV parser: a self-check (`check.py`-style, matching zen-note's
  `check.py`) feeding sample CSV and asserting the derived `today` + 7-day
  `week` array. The only non-trivial logic; everything else is declarative UI +
  thin shell-outs.
- Manual: enable plugin, add desktop widget via the desktop-widget editor,
  click a dot, confirm `feeling export` reflects it and all three surfaces
  update; toggle a global theme and confirm colors follow.

## Open Questions

None — all resolved during brainstorming (layout: today + week strip; surfaces:
desktop + bar; input: row of 10 dots; location: noctalia-v5-plugins repo;
refresh: interval + on-write; binary: PATH with override setting).
