--!nonstrict
-- Bar glyph tinted by today's mood; click toggles the quick logger panel.
local function bucket(v)
  v = tonumber(v)
  if not v or v < 1 then return "outline" end
  if v >= 7 then return "primary" end
  if v >= 4 then return "secondary" end
  return "error"
end

function update()
  local s = noctalia.state.get("feeling")
  barWidget.setGlyph("mood-smile")
  barWidget.setGlyphColor(bucket(s and s.today))
end

function onClick()
  noctalia.togglePanel("noctalia/feeling:feeling-panel")
end

noctalia.setUpdateInterval(60000)
update()
noctalia.state.watch("feeling", update)
