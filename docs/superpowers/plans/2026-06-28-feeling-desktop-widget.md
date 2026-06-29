# Feeling Desktop Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cozy, themable Noctalia v5 plugin that fronts the `feeling` terminal mood tracker — glance at your week and log today's mood in one click.

**Architecture:** A headless `service.luau` runs `feeling export`, parses the CSV, and publishes `state["feeling"]` (today + last 7 days). Three read surfaces — `desktop.luau` (card), `bar.luau` (glyph), `panel.luau` (compact logger) — watch that state and render declaratively with `ui.*`. Clicks publish a `feeling-log-request`; the service runs `feeling N -y` and re-reads. The service is the only writer.

**Tech Stack:** Luau (Noctalia plugin VM), TOML manifest, JSON translations, Python 3.11+ `check.py` validator (matches repo convention — `tomllib`).

## Global Constraints

- `min_noctalia = "5.0.0"` — manifest field, exact value.
- Plugin id: `noctalia/feeling`. Fully-qualified panel id: `noctalia/feeling:feeling-panel`.
- No new runtime dependencies; `feeling` binary is a soft dependency resolved at runtime via the `binary_path` setting (default `"feeling"`).
- All colors MUST be theme tokens — never hex. Valid tokens used: `primary`, `secondary`, `error`, `outline`, `surface`, `surface_variant`, `on_surface_variant`.
- Mood→token buckets (mirror `feeling/src/display/mod.rs`): 7–10 → `primary`; 4–6 → `secondary`; 1–3 → `error`; none/0 → `outline`.
- Logging MUST use the `-y` flag (`feeling N -y`) — the CLI prompts on overwrite and would block in a non-TTY context.
- Every `onClick="name"` must have a matching global `function name`. Every `noctalia.tr("k")` key must exist in `translations/en.json`. Every `getConfig("k")` key must be a declared manifest setting. (Enforced by `check.py`.)
- Plugin lives at `~/projects/noctalia-v5-plugins/feeling/`.

---

## File Structure

```
feeling/
  plugin.toml          manifest: settings, service, desktop_widget, widget, panel
  service.luau         CSV read + parse, state publish, log-request handler
  desktop.luau         cozy card: greeting · today · 10-dot logger · week strip
  bar.luau             bar glyph tinted by today's mood; click toggles panel
  panel.luau           compact 10-dot logger (no week strip)
  translations/en.json all tr() + settings label/description keys
  check.py             static validator: manifest, entries, settings, tr keys, onClick bindings
  README.md            usage
```

Shared helper logic (bucket→token, mood word) is duplicated inline per surface — the snippets are 2 lines; a shared module is not worth the indirection across isolated VMs. (ponytail: inline 2-line helper, extract only if a 4th surface appears.)

---

### Task 1: Manifest, translations, and validator

**Files:**
- Create: `feeling/plugin.toml`
- Create: `feeling/translations/en.json`
- Create: `feeling/check.py`
- Create: `feeling/README.md`

**Interfaces:**
- Produces: manifest setting keys (`binary_path`, `refresh_minutes`, `card_width`, `card_height`, `show_week_strip`, `accent_by_mood`); panel id `noctalia/feeling:feeling-panel`; translation keys consumed by all `.luau` files.

- [ ] **Step 1: Write `plugin.toml`**

```toml
id = "noctalia/feeling"
name = "Feeling"
version = "1.0.0"
min_noctalia = "5.0.0"
author = "Jai"
license = "MIT"
dependencies = []
tags = ["desktop", "panel", "productivity", "health"]
icon = "mood-smile"
description = "A cozy mood tracker desktop widget — log today's feeling and see your week, themed to match."

[[setting]]
key = "binary_path"
type = "string"
default = "feeling"
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

- [ ] **Step 2: Write `translations/en.json`**

```json
{
  "title": "Feeling",
  "greet_unset": "How are you?",
  "greet_good": "Lovely to hear.",
  "greet_okay": "Hanging in there.",
  "greet_bad": "Be gentle with yourself.",
  "word_good": "good",
  "word_okay": "okay",
  "word_bad": "low",
  "not_logged": "not logged yet",
  "today": "Today",
  "no_binary": "Install `feeling` or set its path in plugin settings.",
  "log_failed": "Could not save — is `feeling` installed?",
  "close": "Close",
  "settings": {
    "binary_path": "feeling binary",
    "binary_path_description": "Path or command for the feeling CLI (default: on PATH).",
    "refresh": "Refresh (minutes)",
    "refresh_description": "How often to re-read your mood data from disk.",
    "card_width": "Card width",
    "card_height": "Card height",
    "show_week_strip": "Show week strip",
    "accent_by_mood": "Accent by mood",
    "accent_by_mood_description": "Tint the card border with today's mood color."
  }
}
```

- [ ] **Step 3: Write `check.py`** (validator — extends the zen-note convention with onClick-binding linting)

```python
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
```

- [ ] **Step 4: Write `README.md`**

```markdown
# Feeling

A cozy Noctalia v5 desktop widget for the [`feeling`](https://github.com/qiz-li/feeling)
terminal mood tracker. Glance at your week and log today's mood (1–10) with one
click — themed to match your global Noctalia palette.

## Requires

- Noctalia v5 (`min_noctalia = 5.0.0`)
- The `feeling` CLI on your `PATH` (or set the path in plugin settings)

## Surfaces

- **Desktop widget** — add "Feeling" from the desktop-widget editor.
- **Bar widget** — a mood-tinted glyph; click to open the quick logger panel.

## Settings

Card size, week strip toggle, mood-accent border, refresh interval, and a
`feeling` binary path override.
```

- [ ] **Step 5: Create empty entry stubs so `check.py` can run**

Create `feeling/service.luau`, `feeling/desktop.luau`, `feeling/bar.luau`, `feeling/panel.luau` each containing only:

```lua
--!nonstrict
```

- [ ] **Step 6: Run the validator — expect PASS**

Run: `cd ~/projects/noctalia-v5-plugins/feeling && python3 check.py`
Expected: `Feeling manifest, entries, settings, translations, and handlers valid`

- [ ] **Step 7: Commit**

```bash
cd ~/projects/noctalia-v5-plugins
git add feeling/plugin.toml feeling/translations/en.json feeling/check.py feeling/README.md feeling/*.luau
git commit -m "🎉 feat(feeling): scaffold manifest, translations, validator"
```

---

### Task 2: Service — read CSV, publish state, handle log requests

**Files:**
- Modify: `feeling/service.luau` (replace stub)

**Interfaces:**
- Consumes: settings `binary_path`, `refresh_minutes`.
- Produces: `state["feeling"] = { today = <int|nil>, week = {<int|nil> x7}, days = {<"Mon".."Sun"> x7}, error = <string> }` (week/days oldest→newest, last 7 calendar days ending today). Watches `state["feeling-log-request"] = { value = <int>, at = <number> }`.

- [ ] **Step 1: Write the service**

```lua
--!nonstrict
-- Headless service: reads `feeling export`, derives today + last-7-days,
-- publishes state["feeling"]. Only writer of mood data (via `feeling N -y`).

local function bin()
  local b = noctalia.getConfig("binary_path")
  return (type(b) == "string" and noctalia.string.trim(b) ~= "") and b or "feeling"
end

local function refreshMs()
  return math.max(1, tonumber(noctalia.getConfig("refresh_minutes")) or 5) * 60000
end

-- "YYYY-MM-DD" for an os.time() value
local function dayKey(t) return os.date("%Y-%m-%d", t) end

-- Parse `feeling export` CSV into a date->value map.
local function parseCsv(text)
  local map = {}
  for line in tostring(text):gmatch("[^\r\n]+") do
    local date, val = line:match("^(%d%d%d%d%-%d%d%-%d%d),(%d+)$")
    if date and val then map[date] = tonumber(val) end
  end
  return map
end

-- Build the published payload from a date->value map.
local function buildState(map, errorMessage)
  local now = os.time()
  local todayKey = dayKey(now)
  local week, days = {}, {}
  for i = 6, 0, -1 do
    local t = now - i * 86400
    table.insert(week, map[dayKey(t)])      -- value or nil
    table.insert(days, os.date("%a", t))    -- "Mon".."Sun"
  end
  return {
    today = map[todayKey],
    week = week,
    days = days,
    error = errorMessage or "",
  }
end

local lastRequestAt = 0

local function publishError(msg)
  noctalia.state.set("feeling", buildState({}, msg))
end

local function readState()
  noctalia.runAsync(bin() .. " export", function(out)
    if out.exitCode ~= 0 then
      publishError(noctalia.tr("no_binary"))
      return
    end
    noctalia.state.set("feeling", buildState(parseCsv(out.stdout), nil))
  end)
end

local function logValue(n)
  n = math.floor(tonumber(n) or 0)
  if n < 1 or n > 10 then return end
  noctalia.runAsync(bin() .. " " .. n .. " -y", function(out)
    if out.exitCode ~= 0 then
      publishError(noctalia.tr("log_failed"))
    else
      readState()
    end
  end)
end

readState()
noctalia.setUpdateInterval(refreshMs())

function update() readState() end

noctalia.state.watch("feeling-log-request", function(req)
  if type(req) ~= "table" then return end
  local at = tonumber(req.at) or 0
  if at <= lastRequestAt then return end   -- debounce duplicate notifications
  lastRequestAt = at
  logValue(req.value)
end)
```

- [ ] **Step 2: Add a CSV-parse self-check to `check.py`**

The parse + 7-day-window logic is the only non-trivial code. Mirror it in Python and assert, appended to `check.py` before the final `print`:

```python
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
assert py_week(parsed, today) == [None, 9, None, 3, 7], py_week(parsed, today)  # last 7d: 22..28
```

- [ ] **Step 3: Run the validator — expect PASS**

Run: `cd ~/projects/noctalia-v5-plugins/feeling && python3 check.py`
Expected: prints the valid message with no assertion error.

- [ ] **Step 4: Manual smoke test**

Ensure `feeling` is built and on PATH (`cargo build --release` in the feeling repo, symlink `target/release/feeling` into PATH or set `binary_path`). Then check the parser against real data:

Run: `feeling export`
Expected: CSV with today's row if you've logged. (Service correctness is verified end-to-end in Task 5.)

- [ ] **Step 5: Commit**

```bash
cd ~/projects/noctalia-v5-plugins
git add feeling/service.luau feeling/check.py
git commit -m "🚀 feat(feeling): service reads CSV and publishes mood state"
```

---

### Task 3: Desktop widget — the cozy card

**Files:**
- Modify: `feeling/desktop.luau` (replace stub)

**Interfaces:**
- Consumes: `state["feeling"]` (Task 2); settings `card_width`, `card_height`, `show_week_strip`, `accent_by_mood`.
- Produces: `state["feeling-log-request"]` on dot click (consumed by Task 2). Global handlers `log1`..`log10`.

- [ ] **Step 1: Write the card**

```lua
--!nonstrict
-- Cozy desktop card: greeting · today · 10-dot logger · week strip.
local data = {}

-- mood value -> theme color token (mirrors feeling/src/display/mod.rs buckets)
local function bucket(v)
  v = tonumber(v)
  if not v then return "outline" end
  if v >= 7 then return "primary" end
  if v >= 4 then return "secondary" end
  return "error"
end

local function moodWord(v)
  v = tonumber(v)
  if not v then return "" end
  if v >= 7 then return noctalia.tr("word_good") end
  if v >= 4 then return noctalia.tr("word_okay") end
  return noctalia.tr("word_bad")
end

local function greeting(v)
  v = tonumber(v)
  if not v then return noctalia.tr("greet_unset") end
  if v >= 7 then return noctalia.tr("greet_good") end
  if v >= 4 then return noctalia.tr("greet_okay") end
  return noctalia.tr("greet_bad")
end

-- a single mood dot (filled glyph if <= current, hollow otherwise)
local function dot(n, current)
  local filled = current and n <= current
  return ui.button({
    glyph = filled and "circle-filled" or "circle",
    variant = "ghost",
    color = filled and bucket(current) or "outline",
    onClick = "log" .. n,
  })
end

local function render()
  local width = tonumber(desktopWidget.getConfig("card_width")) or 320
  local height = tonumber(desktopWidget.getConfig("card_height")) or 240
  local showWeek = desktopWidget.getConfig("show_week_strip")
  local accent = desktopWidget.getConfig("accent_by_mood")
  local today = tonumber(data.today)

  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "mood-smile", size = 18, color = "primary" }),
      ui.label({ text = greeting(today), fontSize = 14, fontWeight = "bold", color = "primary", flexGrow = 1 }),
    }),
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "circle-filled", size = 22, color = bucket(today) }),
      ui.label({
        text = today and (tostring(today) .. "  " .. moodWord(today)) or noctalia.tr("not_logged"),
        fontSize = 16,
        fontWeight = "medium",
        color = today and "on_surface" or "on_surface_variant",
        flexGrow = 1,
      }),
    }),
    ui.separator({ color = "outline", opacity = 0.4 }),
  }

  -- 10-dot logger row
  local dots = {}
  for n = 1, 10 do table.insert(dots, dot(n, today)) end
  table.insert(children, ui.row({ align = "center", justify = "space_between" }, dots))

  -- week strip
  if showWeek and type(data.week) == "table" then
    table.insert(children, ui.separator({ color = "outline", opacity = 0.4 }))
    local labels, weekDots = {}, {}
    for i = 1, 7 do
      local v = data.week[i]
      local dayLabel = (type(data.days) == "table" and data.days[i]) or ""
      table.insert(labels, ui.label({ text = dayLabel:sub(1, 1), fontSize = 10, color = "on_surface_variant", flexGrow = 1, textAlign = "center" }))
      table.insert(weekDots, ui.glyph({
        name = v and "circle-filled" or "circle",
        size = 13,
        color = bucket(v),
        flexGrow = 1,
      }))
    end
    table.insert(children, ui.row({ align = "center" }, labels))
    table.insert(children, ui.row({ align = "center" }, weekDots))
  end

  if data.error and data.error ~= "" then
    table.insert(children, ui.label({ text = data.error, fontSize = 11, color = "error", maxLines = 2 }))
  end

  desktopWidget.render(ui.column({
    width = width,
    height = height,
    padding = 20,
    gap = 10,
    fill = "surface",
    border = accent and bucket(today) or "outline",
    borderWidth = 1,
    radius = 22,
    align = "stretch",
  }, children))
end

local function request(n)
  noctalia.state.set("feeling-log-request", { value = n, at = os.clock() })
end

function log1() request(1) end
function log2() request(2) end
function log3() request(3) end
function log4() request(4) end
function log5() request(5) end
function log6() request(6) end
function log7() request(7) end
function log8() request(8) end
function log9() request(9) end
function log10() request(10) end

function update()
  data = noctalia.state.get("feeling") or {}
  render()
end

noctalia.setUpdateInterval(60000)
data = noctalia.state.get("feeling") or {}
render()
noctalia.state.watch("feeling", function(next)
  data = type(next) == "table" and next or {}
  render()
end)
```

- [ ] **Step 2: Run the validator — expect PASS** (confirms all `log1`..`log10` are defined, `tr` keys exist, `getConfig` keys declared)

Run: `cd ~/projects/noctalia-v5-plugins/feeling && python3 check.py`
Expected: valid message.

- [ ] **Step 3: Commit**

```bash
cd ~/projects/noctalia-v5-plugins
git add feeling/desktop.luau
git commit -m "🚀 feat(feeling): cozy desktop card with logger and week strip"
```

---

### Task 4: Bar widget + quick panel

**Files:**
- Modify: `feeling/bar.luau` (replace stub)
- Modify: `feeling/panel.luau` (replace stub)

**Interfaces:**
- Consumes: `state["feeling"]` (Task 2).
- Produces: `state["feeling-log-request"]` from the panel; toggles panel `noctalia/feeling:feeling-panel`. Panel global handlers `log1`..`log10`, `closePanel`.

- [ ] **Step 1: Write `bar.luau`**

```lua
--!nonstrict
-- Bar glyph tinted by today's mood; click toggles the quick logger panel.
local function bucket(v)
  v = tonumber(v)
  if not v then return "outline" end
  if v >= 7 then return "primary" end
  if v >= 4 then return "secondary" end
  return "error"
end

function update()
  local s = noctalia.state.get("feeling")
  barWidget.setGlyph("mood-smile")
  barWidget.setGlyphColor(bucket(s and s.today))
end

function onClick()
  noctalia.togglePanel("noctalia/feeling:feeling-panel")
end

noctalia.setUpdateInterval(60000)
update()
noctalia.state.watch("feeling", update)
```

- [ ] **Step 2: Write `panel.luau`** (compact logger — title, today, 10 dots, close)

```lua
--!nonstrict
local data = {}

local function bucket(v)
  v = tonumber(v)
  if not v then return "outline" end
  if v >= 7 then return "primary" end
  if v >= 4 then return "secondary" end
  return "error"
end

local function moodWord(v)
  v = tonumber(v)
  if not v then return "" end
  if v >= 7 then return noctalia.tr("word_good") end
  if v >= 4 then return noctalia.tr("word_okay") end
  return noctalia.tr("word_bad")
end

local function dot(n, current)
  local filled = current and n <= current
  return ui.button({
    glyph = filled and "circle-filled" or "circle",
    variant = "ghost",
    color = filled and bucket(current) or "outline",
    onClick = "log" .. n,
  })
end

local function render()
  local today = tonumber(data.today)
  local dots = {}
  for n = 1, 10 do table.insert(dots, dot(n, today)) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, padding = 4, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "mood-smile", size = 18, color = "primary" }),
      ui.label({ text = noctalia.tr("title"), fontSize = 15, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "closePanel" }),
    }),
    ui.label({
      text = today and (noctalia.tr("today") .. ": " .. today .. "  " .. moodWord(today)) or noctalia.tr("not_logged"),
      fontSize = 14,
      color = today and "on_surface" or "on_surface_variant",
    }),
    ui.separator({ color = "outline", opacity = 0.4 }),
    ui.row({ align = "center", justify = "space_between" }, dots),
  }))
end

local function request(n)
  noctalia.state.set("feeling-log-request", { value = n, at = os.clock() })
end

function log1() request(1) end
function log2() request(2) end
function log3() request(3) end
function log4() request(4) end
function log5() request(5) end
function log6() request(6) end
function log7() request(7) end
function log8() request(8) end
function log9() request(9) end
function log10() request(10) end
function closePanel() panel.close() end

function update()
  data = noctalia.state.get("feeling") or {}
  render()
end

function onOpen()
  data = noctalia.state.get("feeling") or {}
  render()
end

noctalia.state.watch("feeling", function(next)
  data = type(next) == "table" and next or {}
  render()
end)
```

- [ ] **Step 3: Run the validator — expect PASS**

Run: `cd ~/projects/noctalia-v5-plugins/feeling && python3 check.py`
Expected: valid message.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/noctalia-v5-plugins
git add feeling/bar.luau feeling/panel.luau
git commit -m "🚀 feat(feeling): bar glyph and quick logger panel"
```

---

### Task 5: End-to-end verification in Noctalia

**Files:** none (manual acceptance).

- [ ] **Step 1: Ensure `feeling` is available**

Run: `which feeling || (cd ~/feeling && cargo build --release)`
If not on PATH, note the absolute path to set as `binary_path` in plugin settings.

- [ ] **Step 2: Confirm the path source + enable the plugin**

The `~/projects/noctalia-v5-plugins` path source already exists. Then:

Run: `noctalia msg plugins list` (confirm `noctalia/feeling` appears)
Run: `noctalia msg plugins enable noctalia/feeling`
Expected: plugin enables without "requires newer Noctalia".

- [ ] **Step 3: Add the desktop widget**

Open the desktop-widget editor (`noctalia msg` desktop-widgets, or Settings), add "Feeling". Expected: cozy card renders with greeting, today line, 10 dots, week strip.

- [ ] **Step 4: Log a mood from the card**

Click dot 8. Expected within ~1s: today line shows "8 good", dots fill to 8, card border tints `primary` (if accent on), week strip's last dot updates.

Run: `feeling export`
Expected: today's row reads `,8`.

- [ ] **Step 5: Verify the bar widget + panel**

Add the Feeling bar widget. Expected: glyph tinted to today's bucket. Click it → panel opens with the compact logger. Click dot 3 → `feeling export` today row reads `,3`; bar glyph retints to `error`; desktop card updates too (shared state).

- [ ] **Step 6: Verify theming**

Switch the global Noctalia theme/palette. Expected: card surface, border, text, and mood dots all shift with the palette — no stale colors.

- [ ] **Step 7: Verify the missing-binary path**

Set `binary_path` to a bogus value in settings. Expected: card shows the `no_binary` line, no crash. Restore the setting.

- [ ] **Step 8: Final commit (version bump only if changes were needed)**

```bash
cd ~/projects/noctalia-v5-plugins
git add -A feeling
git commit -m "✅ feat(feeling): verified end-to-end in Noctalia v5" --allow-empty
```

---

## Self-Review

**Spec coverage:**
- Service + CSV read + state publish → Task 2. ✓
- Desktop card (greeting/today/10-dot/week strip) → Task 3. ✓
- Bar widget + panel → Task 4. ✓
- Mood→token buckets mirroring CLI → Global Constraints + bucket() in Tasks 3/4. ✓
- `-y` non-interactive log → Task 2 `logValue`. ✓
- Interval + on-write refresh → Task 2 (`setUpdateInterval` + `feeling-log-request` watch). ✓
- Settings (binary_path, refresh, card sizes, week strip, accent) → Task 1 manifest. ✓
- Error handling (missing binary, empty CSV, log fail, malformed row) → Task 2 (`publishError`, `parseCsv` skips bad rows) + Task 3 error label + Task 5 Step 7. ✓
- Location in noctalia-v5-plugins repo → all paths. ✓
- Testing (CSV self-check + manual) → Task 2 Step 2 + Task 5. ✓

**Placeholder scan:** No TBD/TODO; all code blocks complete; no "similar to Task N" (dot/bucket code repeated verbatim per surface as required by isolated VMs).

**Type consistency:** State payload `{today, week, days, error}` defined in Task 2 and consumed with those exact keys in Tasks 3/4. `feeling-log-request` `{value, at}` produced in Tasks 3/4, consumed in Task 2. `bucket()` signature identical across surfaces. `log1`..`log10`/`closePanel` handlers defined where referenced (validated by `check.py`).

**Note on TDD:** Luau has no runnable test harness outside the Noctalia VM. The non-trivial logic (CSV parse + 7-day window) gets a Python mirror self-check in `check.py` (Task 2 Step 2); UI surfaces are validated statically (`check.py` handler/tr/config linting) and verified manually in Task 5. This is the honest test strategy for this platform, not skipped tests.
