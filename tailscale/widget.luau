--!nonstrict
local running = false
local function render(data)
  data = type(data) == "table" and data or {}
  running = data.running == true
  local online = 0
  for _, peer in ipairs(data.peers or {}) do if peer.online then online += 1 end end
  barWidget.setGlyph(running and "network" or "network-off")
  barWidget.setText(noctalia.getConfig("show_ip") and tostring(data.ip or "") or tostring(online))
  barWidget.setTooltip(data.error or noctalia.tr("summary", { state = data.state or "--", peers = online }))
end
render(noctalia.state.get("tailscale")); noctalia.state.watch("tailscale", render)
function onClick() noctalia.togglePanel("noctalia/tailscale:tailscale-panel") end
function onMiddleClick() noctalia.state.set("tailscale-command", { action = running and "down" or "up", nonce = os.clock() }) end
