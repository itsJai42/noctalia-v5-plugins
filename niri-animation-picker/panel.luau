--!nonstrict
local files = {}
local slots = {}
local status = ""
local render

local function apply(index)
  local name = slots[index]
  if not name then return end
  local target = noctalia.expandPath(noctalia.getConfig("target_file"))
  local preset = noctalia.expandPath(noctalia.getConfig("animations_folder")) .. "/" .. name
  local current = noctalia.readFile(target) or ""
  local lines = {}
  for line in (current .. "\n"):gmatch("(.-)\n") do
    if not line:find("// noctalia/niri-animation-picker", 1, true) then table.insert(lines, line) end
  end
  table.insert(lines, "include \"" .. preset .. "\" // noctalia/niri-animation-picker")
  local ok, err = noctalia.writeFile(target, table.concat(lines, "\n") .. "\n")
  status = ok and noctalia.tr("applied", { file = name }) or tostring(err or noctalia.tr("write_failed"))
  if ok then noctalia.notify(noctalia.tr("title"), status) end
  render()
end

render = function()
  slots = {}
  local rows = {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = status, color = "on_surface_variant" }),
  }
  local buttons = {}
  for i, name in ipairs(files) do
    if i > 20 then break end
    slots[i] = name
    table.insert(buttons, ui.button({ text = name, glyph = "sparkles", onClick = "pick" .. tostring(i) }))
  end
  table.insert(rows, ui.scroll({ flexGrow = 1, gap = 8 }, buttons))
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, rows))
end

function onOpen()
  files = {}
  for _, name in ipairs(noctalia.listDir(noctalia.getConfig("animations_folder")) or {}) do if name:match("%.kdl$") then table.insert(files, name) end end
  table.sort(files); status = #files == 0 and noctalia.tr("empty") or noctalia.tr("found", { count = #files }); render()
end
function closePanel() panel.close() end
function pick1() apply(1) end
function pick2() apply(2) end
function pick3() apply(3) end
function pick4() apply(4) end
function pick5() apply(5) end
function pick6() apply(6) end
function pick7() apply(7) end
function pick8() apply(8) end
function pick9() apply(9) end
function pick10() apply(10) end
function pick11() apply(11) end
function pick12() apply(12) end
function pick13() apply(13) end
function pick14() apply(14) end
function pick15() apply(15) end
function pick16() apply(16) end
function pick17() apply(17) end
function pick18() apply(18) end
function pick19() apply(19) end
function pick20() apply(20) end
