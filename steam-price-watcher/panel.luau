--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  local rows = {}
  for _, game in ipairs(data.games or {}) do table.insert(rows, ui.row({ justify = "space_between" }, { ui.label({ text = game.name, color = game.reached and "primary" or "on_surface" }), ui.label({ text = tostring(game.price) .. " / " .. tostring(game.target), color = "on_surface_variant" }) })) end
  if #rows == 0 then table.insert(rows, ui.label({ text = noctalia.tr("empty"), color = "on_surface_variant" })) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, { ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }), ui.scroll({ flexGrow = 1, gap = 8 }, rows) }))
end
render(noctalia.state.get("prices")); noctalia.state.watch("prices", render)
function closePanel() panel.close() end
