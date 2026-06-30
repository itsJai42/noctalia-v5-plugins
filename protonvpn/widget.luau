--!nonstrict
local connected = false
local function render(data)
  data = type(data) == "table" and data or {}
  connected = data.connected == true
  barWidget.setGlyph(connected and "shield-lock" or "shield-off")
  barWidget.setGlyphColor(connected and "primary" or "on_surface_variant")
  barWidget.setTooltip(data.status or noctalia.tr("unavailable"))
end
render(noctalia.state.get("proton")); noctalia.state.watch("proton", render)
function onClick() noctalia.togglePanel("noctalia/protonvpn:proton-panel") end
function onMiddleClick() noctalia.state.set("proton-command", { action = connected and "disconnect" or "connect", nonce = os.clock() }) end
