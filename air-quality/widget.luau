--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  barWidget.setGlyph(data.error and "alert-circle" or "wind")
  barWidget.setText(data.us_aqi and tostring(math.floor(data.us_aqi + 0.5)) or "--")
  barWidget.setTooltip(data.error or ("AQI " .. tostring(data.us_aqi or "--") .. "\nPM2.5 " .. tostring(data.pm2_5 or "--") .. "\nPM10 " .. tostring(data.pm10 or "--")))
end
render(noctalia.state.get("air"))
noctalia.state.watch("air", render)
function onClick() noctalia.togglePanel("noctalia/air-quality:air-panel") end
function onMiddleClick() noctalia.state.set("air-refresh", os.clock()) end
