--!nonstrict
local ip = ""
local function render(data)
  data = type(data) == "table" and data or {}
  ip = data.ip or ""
  barWidget.setGlyph(data.error and "alert-circle" or "network")
  barWidget.setText(ip ~= "" and ip or "--")
  barWidget.setTooltip(data.error or table.concat({ tostring(data.city or ""), tostring(data.region or ""), tostring(data.org or "") }, "\n"))
end
render(noctalia.state.get("ip"))
noctalia.state.watch("ip", render)
function onClick() noctalia.togglePanel("noctalia/ip-monitor:ip-panel") end
function onRightClick() if ip ~= "" then noctalia.copyToClipboard(ip, "text/plain"); noctalia.notify(noctalia.tr("title"), noctalia.tr("copied")) end end
