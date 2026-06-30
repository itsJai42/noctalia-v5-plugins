--!nonstrict
local stateKey = "hotkeys-cheatsheet"
local commandKey = "hotkeys-cheatsheet-command"
local data = {}

local function selectedSet()
  local sets = type(data.sets) == "table" and data.sets or {}
  for _, set in ipairs(sets) do
    if set.id == data.selected then return set end
  end
  return sets[1]
end

local function enabledSets()
  local out = {}
  for _, set in ipairs(type(data.sets) == "table" and data.sets or {}) do
    if set.enabled then table.insert(out, set) end
  end
  return out
end

local function request(action, id)
  noctalia.state.set(commandKey, { action = action, id = id, nonce = os.clock() })
end

local function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  local set = selectedSet()
  local count = set and tonumber(set.count) or 0
  barWidget.setGlyph(data.error and "alert-circle" or "keyboard")
  barWidget.setGlyphColor(data.error and "error" or "primary")
  barWidget.setText(count and tostring(count) or "--")
  if data.error then
    barWidget.setTooltip(data.error)
  elseif set then
    barWidget.setTooltip(tostring(set.name or noctalia.tr("title")) .. " · " .. tostring(count) .. "\n" .. noctalia.tr("widget_tooltip"))
  else
    barWidget.setTooltip(noctalia.tr("loading"))
  end
end

function update()
  render(noctalia.state.get(stateKey))
end

function onClick()
  noctalia.togglePanel("noctalia/hotkeys-cheatsheet:hotkeys-panel")
end

function onMiddleClick()
  local sets = enabledSets()
  if #sets == 0 then return end
  local current = 1
  for i, set in ipairs(sets) do if set.id == data.selected then current = i end end
  local nextSet = sets[(current % #sets) + 1]
  request("select", nextSet.id)
end

function onRightClick()
  request("refresh")
end

render(noctalia.state.get(stateKey))
noctalia.state.watch(stateKey, render)
