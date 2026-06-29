--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  panel.render(ui.column({ flexGrow = 1, gap = 14, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = tostring(data.provider or noctalia.getConfig("provider")), fontSize = 18, fontWeight = "medium" }),
    ui.label({ text = noctalia.tr("sessions", { count = data.sessions or 0 }), fontSize = 24 }),
    ui.label({ text = noctalia.tr("messages", { count = data.messages or 0 }), fontSize = 24 }),
    ui.label({ text = data.error or "", color = "error" }),
  }))
end
render(noctalia.state.get("usage")); noctalia.state.watch("usage", render)
function closePanel() panel.close() end
