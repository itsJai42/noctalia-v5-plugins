--!nonstrict
local running = false
local function render(value)
  running = value == true
  barWidget.setGlyph(running and "layout-columns" or "layout-off")
  barWidget.setText(tostring(noctalia.getConfig("max_visible")))
  barWidget.setTooltip(running and noctalia.tr("running") or noctalia.tr("stopped"))
end
render(noctalia.state.get("auto-tile-running")); noctalia.state.watch("auto-tile-running", render)
function onClick() noctalia.state.set("auto-tile-command", { action = running and "stop" or "start", nonce = os.clock() }) end
