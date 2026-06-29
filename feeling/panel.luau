--!nonstrict
local data = {}

local function bucket(v)
  v = tonumber(v)
  if not v or v < 1 then return "outline" end
  if v >= 7 then return "primary" end
  if v >= 4 then return "secondary" end
  return "error"
end

local function moodWord(v)
  v = tonumber(v)
  if not v then return "" end
  if v >= 7 then return noctalia.tr("word_good") end
  if v >= 4 then return noctalia.tr("word_okay") end
  return noctalia.tr("word_bad")
end

local function dot(n, current)
  local filled = current and n <= current
  return ui.button({
    glyph = filled and "circle-filled" or "circle",
    variant = "ghost",
    color = filled and bucket(current) or "outline",
    onClick = "log" .. n,
  })
end

local function render()
  local today = tonumber(data.today)
  local dots = {}
  for n = 1, 10 do table.insert(dots, dot(n, today)) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, padding = 4, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "mood-smile", size = 18, color = "primary" }),
      ui.label({ text = noctalia.tr("title"), fontSize = 15, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "closePanel" }),
    }),
    ui.label({
      text = today and (noctalia.tr("today") .. ": " .. today .. "  " .. moodWord(today)) or noctalia.tr("not_logged"),
      fontSize = 14,
      color = today and "on_surface" or "on_surface_variant",
    }),
    ui.separator({ color = "outline", opacity = 0.4 }),
    ui.row({ align = "center", justify = "space_between" }, dots),
  }))
end

local function request(n)
  noctalia.state.set("feeling-log-request", { value = n, at = os.clock() })
end

function log1() request(1) end
function log2() request(2) end
function log3() request(3) end
function log4() request(4) end
function log5() request(5) end
function log6() request(6) end
function log7() request(7) end
function log8() request(8) end
function log9() request(9) end
function log10() request(10) end
function closePanel() panel.close() end

function update()
  data = noctalia.state.get("feeling") or {}
  render()
end

function onOpen()
  data = noctalia.state.get("feeling") or {}
  render()
end

noctalia.state.watch("feeling", function(next)
  data = type(next) == "table" and next or {}
  render()
end)
