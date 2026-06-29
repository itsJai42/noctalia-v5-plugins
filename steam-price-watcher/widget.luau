--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  barWidget.setGlyph("brand-steam")
  barWidget.setGlyphColor((data.reached or 0) > 0 and "primary" or "on_surface")
  barWidget.setText(tostring(data.reached or 0) .. "/" .. tostring(#(data.games or {})))
  barWidget.setTooltip((data.reached or 0) > 0 and noctalia.tr("targets", { count = data.reached }) or noctalia.tr("no_targets"))
end
render(noctalia.state.get("prices")); noctalia.state.watch("prices", render)
function onClick() noctalia.togglePanel("noctalia/steam-price-watcher:prices-panel") end
