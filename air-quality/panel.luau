--!nonstrict
local data = {}
local function value(label, key) return ui.row({ justify = "space_between" }, { ui.label({ text = label }), ui.label({ text = tostring(data[key] or "--"), color = "primary" }) }) end
local function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between", align = "center" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = data.error or ("AQI " .. tostring(data.us_aqi or "--")), fontSize = 32, fontWeight = "bold", color = data.error and "error" or "primary" }),
    value("PM2.5", "pm2_5"), value("PM10", "pm10"), value("Ozone", "ozone"), value("NO₂", "nitrogen_dioxide"), value("CO", "carbon_monoxide"), value("SO₂", "sulphur_dioxide"),
  }))
end
render(noctalia.state.get("air"))
noctalia.state.watch("air", render)
function closePanel() panel.close() end
