--!nonstrict
local path = (noctalia.getenv("XDG_STATE_HOME") or ((noctalia.getenv("HOME") or "") .. "/.local/state")) .. "/noctalia/sticky-notes.json"
local notes = {}
local draft = ""
local slots = {}
local render

local function load()
  local raw = noctalia.readFile(path)
  local decoded = raw and noctalia.json.decode(raw) or nil
  notes = type(decoded) == "table" and decoded or {}
end
local function save()
  local encoded = noctalia.json.encode(notes, true)
  if encoded then noctalia.writeFile(path, encoded) end
end
local function remove(index) if slots[index] then table.remove(notes, slots[index]); save(); render() end end

render = function()
  slots = {}
  local items = {}
  for i, note in ipairs(notes) do
    if i > 20 then break end
    slots[i] = i
    table.insert(items, ui.box({ fill = "surface_variant", radius = 10 }, { ui.row({ gap = 8, align = "center" }, { ui.label({ text = tostring(note), flexGrow = 1 }), ui.button({ glyph = "trash", onClick = "delete" .. tostring(i) }) }) }))
  end
  if #items == 0 then table.insert(items, ui.label({ text = noctalia.tr("empty"), color = "on_surface_variant" })) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.scroll({ flexGrow = 1, gap = 8 }, items),
    ui.input({ key = "new-note", placeholder = noctalia.tr("placeholder"), onChange = "onDraft", onSubmit = "addNote" }),
    ui.button({ text = noctalia.tr("add"), glyph = "plus", variant = "primary", onClick = "addNote", enabled = draft ~= "" }),
  }))
end
function onDraft(value) draft = value; render() end
function addNote(value)
  local text = type(value) == "string" and value ~= "" and value or draft
  if text == "" then return end
  table.insert(notes, 1, text); draft = ""; save(); render()
end
function closePanel() panel.close() end
function onOpen() load(); render() end
function delete1() remove(1) end
function delete2() remove(2) end
function delete3() remove(3) end
function delete4() remove(4) end
function delete5() remove(5) end
function delete6() remove(6) end
function delete7() remove(7) end
function delete8() remove(8) end
function delete9() remove(9) end
function delete10() remove(10) end
function delete11() remove(11) end
function delete12() remove(12) end
function delete13() remove(13) end
function delete14() remove(14) end
function delete15() remove(15) end
function delete16() remove(16) end
function delete17() remove(17) end
function delete18() remove(18) end
function delete19() remove(19) end
function delete20() remove(20) end
