--!nonstrict
function onOpen()
  panel.render(ui.column({ flexGrow = 1, gap = 16, align = "center", justify = "center" }, {
    ui.glyph({ name = "puzzle", size = 48, color = "primary" }),
    ui.label({ text = noctalia.tr("title"), fontSize = 18, fontWeight = "bold" }),
    ui.label({ text = noctalia.tr("built_in"), color = "on_surface_variant", textAlign = "center" }),
    ui.button({ text = noctalia.tr("close"), onClick = "closePanel" }),
  }))
end
function closePanel() panel.close() end
