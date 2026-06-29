--!nonstrict
local data = {}

local function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  local width = tonumber(desktopWidget.getConfig("card_width")) or 380
  local height = tonumber(desktopWidget.getConfig("card_height")) or 250
  local fontSize = tonumber(desktopWidget.getConfig("quote_font_size")) or 20
  local text = type(data.text) == "string" and data.text or ""
  local authorName = type(data.author) == "string" and data.author or ""
  local quote = text ~= "" and text or noctalia.tr("loading")
  local author = authorName ~= "" and ("— " .. authorName) or ""
  local nextLabel = ""
  local nextAt = tonumber(data.next_at) or 0
  if nextAt > 0 then
    nextLabel = noctalia.tr("next_at", { time = noctalia.formatTime("%H:%M", nextAt) })
  end

  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "sparkles", size = 18, color = "primary" }),
      ui.label({ text = noctalia.tr("title"), fontSize = 13, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "refresh", variant = "ghost", onClick = "nextQuote", enabled = not data.loading }),
    }),
    ui.separator({ color = "outline", opacity = 0.45 }),
    ui.label({ text = "“" .. quote .. "”", fontSize = fontSize, fontWeight = "medium", maxWidth = width - 44, maxLines = 9, flexGrow = 1 }),
    ui.label({ text = author, fontSize = 13, color = "on_surface_variant", textAlign = "end", visible = author ~= "" }),
  }

  if data.error and data.error ~= "" then
    table.insert(children, ui.label({ text = data.error, fontSize = 11, color = "error", maxLines = 2 }))
  end

  table.insert(children, ui.row({ align = "center", gap = 8 }, {
    ui.button({ text = noctalia.tr("attribution"), glyph = "external-link", variant = "ghost", onClick = "openZenQuotes" }),
    ui.spacer({ flexGrow = 1 }),
    ui.label({ text = nextLabel, fontSize = 11, color = "on_surface_variant", visible = nextLabel ~= "" }),
  }))

  desktopWidget.render(ui.column({
    width = width,
    height = height,
    padding = 22,
    gap = 12,
    fill = "surface_variant",
    border = "outline",
    borderWidth = 1,
    radius = 24,
    align = "stretch",
  }, children))
end

function nextQuote()
  noctalia.state.set("next-request", os.clock())
end

function openZenQuotes()
  noctalia.runAsync("xdg-open https://zenquotes.io")
end

function update()
  render(noctalia.state.get("quote"))
end

noctalia.setUpdateInterval(60000)
render(noctalia.state.get("quote"))
noctalia.state.watch("quote", render)
