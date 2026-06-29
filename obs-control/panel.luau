--!nonstrict
local status = ""
local render
local function prefix()
  local url = noctalia.getConfig("websocket_url")
  return "obs-cmd " .. (url ~= "" and ("--websocket '" .. url:gsub("'", "'\\''") .. "' ") or "")
end
local function run(command)
  status = noctalia.tr("running_command"); render()
  noctalia.runAsync(prefix() .. command, function(result) status = result.exitCode == 0 and noctalia.tr("done") or (result.stderr ~= "" and result.stderr or noctalia.tr("failed")); render() end)
end
render = function()
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.row({ gap = 8 }, { ui.button({ text = noctalia.tr("record"), glyph = "circle-dot", onClick = "toggleRecord", flexGrow = 1 }), ui.button({ text = noctalia.tr("stream"), glyph = "broadcast", onClick = "toggleStream", flexGrow = 1 }) }),
    ui.row({ gap = 8 }, { ui.button({ text = noctalia.tr("replay"), glyph = "repeat", onClick = "toggleReplay", flexGrow = 1 }), ui.button({ text = noctalia.tr("save_replay"), glyph = "device-floppy", onClick = "saveReplay", flexGrow = 1 }) }),
    ui.label({ text = status, color = status == noctalia.tr("failed") and "error" or "on_surface_variant" }),
  }))
end
function toggleRecord() run("recording toggle") end
function toggleStream() run("streaming toggle") end
function toggleReplay() run("replay toggle") end
function saveReplay() run("replay save") end
function closePanel() panel.close() end
function onOpen() render() end
