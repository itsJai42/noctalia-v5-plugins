--!nonstrict
local wallpapers = {}
local slots = {}
local render
local function directory()
  local configured = noctalia.getConfig("wallpaper_directory")
  return configured ~= "" and noctalia.expandPath(configured) or noctalia.wallpaperDirectory() or noctalia.expandPath("~/Pictures/Wallpapers")
end
local function apply(index)
  local path = slots[index]
  if path then noctalia.setWallpaper(path); noctalia.notify(noctalia.tr("title"), noctalia.tr("applied", { name = path:match("([^/]+)$") or path })) end
end
render = function()
  slots = {}
  local rows = {}
  local row = {}
  for i, path in ipairs(wallpapers) do
    if i > 20 then break end
    slots[i] = path
    table.insert(row, ui.column({ gap = 4, align = "center", flexGrow = 1 }, {
      ui.image({ path = path, width = 200, height = 120, fit = "cover", radius = 10, onClick = "pick" .. tostring(i) }),
      ui.label({ text = path:match("([^/]+)$") or path, maxLines = 1, maxWidth = 200 }),
    }))
    if #row == 4 or i == math.min(#wallpapers, 20) then table.insert(rows, ui.row({ gap = 10 }, row)); row = {} end
  end
  if #rows == 0 then table.insert(rows, ui.label({ text = noctalia.tr("empty"), color = "on_surface_variant" })) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.scroll({ flexGrow = 1, gap = 10 }, rows),
  }))
end
function onOpen()
  wallpapers = {}
  local dir = directory()
  for _, name in ipairs(noctalia.listDir(dir) or {}) do if name:lower():match("%.png$") or name:lower():match("%.jpe?g$") or name:lower():match("%.webp$") then table.insert(wallpapers, dir .. "/" .. name) end end
  table.sort(wallpapers); render()
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
