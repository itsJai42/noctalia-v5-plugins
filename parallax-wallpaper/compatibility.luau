--!nonstrict
function onOpen()
  panel.render(ui.column({ flexGrow = 1, gap = 16, align = "center", justify = "center" }, {
    ui.glyph({ name = "photo-off", size = 48, color = "on_surface_variant" }),
    ui.label({ text = noctalia.tr("title"), fontSize = 18, fontWeight = "bold" }),
    ui.label({ text = noctalia.tr("unsupported"), color = "on_surface_variant", textAlign = "center" }),
    ui.button({ text = noctalia.tr("close"), onClick = "closePanel" }),
  }))
end
function closePanel() panel.close() end
