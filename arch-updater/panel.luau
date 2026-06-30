--!nonstrict
local lines = {}
local status = ""
local render

local function command()
  local parts = { "(" .. noctalia.getConfig("system_cmd") .. ")", "(" .. noctalia.getConfig("aur_cmd") .. ")" }
  if noctalia.getConfig("include_flatpak") then table.insert(parts, "flatpak remote-ls --updates --columns=application 2>/dev/null") end
  return table.concat(parts, "; ")
end

local function refresh()
  status = noctalia.tr("checking")
  render()
  noctalia.runAsync(command(), function(result)
    lines = {}
    for line in result.stdout:gmatch("[^\r\n]+") do table.insert(lines, line) end
    status = #lines == 0 and noctalia.tr("up_to_date") or noctalia.tr("available", { count = #lines })
    render()
  end, 60000)
end

render = function()
  local rows = {
    ui.row({ align = "center", justify = "space_between" }, {
      ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", onClick = "closePanel" }),
    }),
    ui.label({ text = status, color = "on_surface_variant" }),
  }
  local list = {}
  for _, line in ipairs(lines) do table.insert(list, ui.label({ text = line, maxLines = 1 })) end
  table.insert(rows, ui.scroll({ flexGrow = 1, gap = 6 }, list))
  table.insert(rows, ui.row({ gap = 8 }, {
    ui.button({ text = noctalia.tr("refresh"), glyph = "refresh", onClick = "refreshUpdates" }),
    ui.button({ text = noctalia.tr("install"), glyph = "download", variant = "primary", onClick = "installUpdates" }),
  }))
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, rows))
end

function onOpen() refresh() end
function refreshUpdates() refresh() end
function installUpdates() noctalia.runInTerminal(noctalia.getConfig("update_cmd")) end
function closePanel() panel.close() end
