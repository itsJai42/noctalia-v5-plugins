--!nonstrict
local data = {}
local function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  local rows = {}
  for _, peer in ipairs(data.peers or {}) do table.insert(rows, ui.row({ justify = "space_between" }, { ui.label({ text = (peer.online and "● " or "○ ") .. peer.name }), ui.label({ text = peer.ip or "", color = "on_surface_variant" }) })) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = tostring(data.state or data.error or "--") .. "  " .. tostring(data.ip or ""), fontWeight = "medium" }),
    ui.scroll({ flexGrow = 1, gap = 8 }, rows),
    ui.button({ text = data.running and noctalia.tr("disconnect") or noctalia.tr("connect"), variant = "primary", onClick = "toggleConnection" }),
  }))
end
render(noctalia.state.get("tailscale")); noctalia.state.watch("tailscale", render)
function toggleConnection() noctalia.state.set("tailscale-command", { action = data.running and "down" or "up", nonce = os.clock() }) end
function closePanel() panel.close() end
