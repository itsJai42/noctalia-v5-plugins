--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  panel.render(ui.column({ flexGrow = 1, gap = 16, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = data.repository or noctalia.getConfig("repository"), fontSize = 14, fontWeight = "medium" }),
    ui.row({ gap = 12 }, {
      ui.box({ flexGrow = 1, fill = "surface_variant", radius = 10 }, { ui.column({ gap = 4 }, { ui.label({ text = tostring(data.issues or 0), fontSize = 28, color = "primary" }), ui.label({ text = noctalia.tr("issues") }) }) }),
      ui.box({ flexGrow = 1, fill = "surface_variant", radius = 10 }, { ui.column({ gap = 4 }, { ui.label({ text = tostring(data.requests or 0), fontSize = 28, color = "primary" }), ui.label({ text = noctalia.tr("requests") }) }) }),
    }),
    ui.label({ text = data.error or "", color = "error" }),
  }))
end
render(noctalia.state.get("git")); noctalia.state.watch("git", render)
function closePanel() panel.close() end
