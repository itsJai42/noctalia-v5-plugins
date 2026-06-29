--!nonstrict
local function prefix()
  local url = noctalia.getConfig("websocket_url")
  return "obs-cmd " .. (url ~= "" and ("--websocket '" .. url:gsub("'", "'\\''") .. "' ") or "")
end
local function refresh()
  noctalia.runAsync(prefix() .. "recording status-active", function(result)
    local active = result.exitCode == 0
    barWidget.setGlyph(active and "circle-dot" or "video")
    barWidget.setGlyphColor(active and "error" or "on_surface")
    barWidget.setTooltip(active and noctalia.tr("recording") or noctalia.tr("idle"))
  end)
end
function update() noctalia.setUpdateInterval(3000); refresh() end
function onClick() noctalia.togglePanel("noctalia/obs-control:obs-panel") end
function onMiddleClick() noctalia.runAsync(prefix() .. "recording toggle", function() refresh() end) end
