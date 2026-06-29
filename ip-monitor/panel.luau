--!nonstrict
local function row(label, value) return ui.row({ justify = "space_between" }, { ui.label({ text = label }), ui.label({ text = tostring(value or "--"), color = "primary" }) }) end
local function render(data)
  data = type(data) == "table" and data or {}
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    row("IP", data.ip), row(noctalia.tr("city"), data.city), row(noctalia.tr("region"), data.region), row(noctalia.tr("country"), data.country_name), row(noctalia.tr("provider"), data.org), row(noctalia.tr("timezone"), data.timezone),
  }))
end
render(noctalia.state.get("ip")); noctalia.state.watch("ip", render)
function closePanel() panel.close() end
