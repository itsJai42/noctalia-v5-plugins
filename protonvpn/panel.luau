--!nonstrict
local data = {}
local function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.glyph({ name = data.connected and "shield-lock" or "shield-off", size = 48, color = data.connected and "primary" or "on_surface_variant" }),
    ui.label({ text = data.status or noctalia.tr("unavailable"), color = "on_surface_variant" }),
    ui.button({ text = data.connected and noctalia.tr("disconnect") or noctalia.tr("connect"), variant = "primary", onClick = "toggleConnection" }),
    ui.row({ gap = 8 }, { ui.button({ text = noctalia.tr("secure_core"), onClick = "secureCore", flexGrow = 1 }), ui.button({ text = "P2P", onClick = "connectP2p", flexGrow = 1 }) }),
  }))
end
render(noctalia.state.get("proton")); noctalia.state.watch("proton", render)
local function command(action) noctalia.state.set("proton-command", { action = action, nonce = os.clock() }) end
function toggleConnection() command(data.connected and "disconnect" or "connect") end
function secureCore() command("secure-core") end
function connectP2p() command("p2p") end
function closePanel() panel.close() end
