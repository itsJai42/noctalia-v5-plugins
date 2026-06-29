--!nonstrict
local function refresh()
  noctalia.runAsync("niri msg keyboard-layouts", function(result)
    local active = result.stdout:match("%*%s*%d+%s+([^\n]+)")
    barWidget.setText(active and active:match("^%s*(.-)%s*$") or "?")
    barWidget.setGlyph("language")
    barWidget.setTooltip(active or noctalia.tr("unavailable"))
  end)
end

function update()
  noctalia.setUpdateInterval(barWidget.getConfig("poll_interval_ms"))
  refresh()
end

function onClick() noctalia.runAsync("niri msg action switch-layout next", function() refresh() end) end
function onMiddleClick() noctalia.runAsync("niri msg action switch-layout prev", function() refresh() end) end
function onIpc(event) if event == "refresh" then refresh() end end
