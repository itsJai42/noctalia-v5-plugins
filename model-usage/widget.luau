--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  barWidget.setGlyph(data.error and "alert-circle" or "chart-bar")
  barWidget.setText(tostring(data.messages or "--"))
  barWidget.setTooltip(data.error or noctalia.tr("summary", { provider = data.provider or "", sessions = data.sessions or 0, messages = data.messages or 0 }))
end
render(noctalia.state.get("usage")); noctalia.state.watch("usage", render)
function onClick() noctalia.togglePanel("noctalia/model-usage:usage-panel") end
