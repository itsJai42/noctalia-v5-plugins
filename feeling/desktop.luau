--!nonstrict
-- Cozy desktop card: greeting · today · 10-dot logger · week strip.
local data = {}

-- mood value -> theme color token (mirrors feeling/src/display/mod.rs buckets)
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

local function greeting(v)
  v = tonumber(v)
  if not v then return noctalia.tr("greet_unset") end
  if v >= 7 then return noctalia.tr("greet_good") end
  if v >= 4 then return noctalia.tr("greet_okay") end
  return noctalia.tr("greet_bad")
end

-- a single mood dot (filled glyph if <= current, hollow otherwise)
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
  local width = tonumber(desktopWidget.getConfig("card_width")) or 320
  local height = tonumber(desktopWidget.getConfig("card_height")) or 240
  local showWeek = desktopWidget.getConfig("show_week_strip")
  local accent = desktopWidget.getConfig("accent_by_mood")
  local today = tonumber(data.today)

  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "mood-smile", size = 18, color = "primary" }),
      ui.label({ text = greeting(today), fontSize = 14, fontWeight = "bold", color = "primary", flexGrow = 1 }),
    }),
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "circle-filled", size = 22, color = bucket(today) }),
      ui.label({
        text = today and (tostring(today) .. "  " .. moodWord(today)) or noctalia.tr("not_logged"),
        fontSize = 16,
        fontWeight = "medium",
        color = today and "on_surface" or "on_surface_variant",
        flexGrow = 1,
      }),
    }),
    ui.separator({ color = "outline", opacity = 0.4 }),
  }

  -- 10-dot logger row
  local dots = {}
  for n = 1, 10 do table.insert(dots, dot(n, today)) end
  table.insert(children, ui.row({ align = "center", justify = "space_between" }, dots))

  -- week strip
  if showWeek and type(data.week) == "table" then
    table.insert(children, ui.separator({ color = "outline", opacity = 0.4 }))
    local labels, weekDots = {}, {}
    for i = 1, 7 do
      local v = data.week[i]
      local dayLabel = (type(data.days) == "table" and data.days[i]) or ""
      table.insert(labels, ui.label({ text = dayLabel:sub(1, 1), fontSize = 10, color = "on_surface_variant", flexGrow = 1, textAlign = "center" }))
      table.insert(weekDots, ui.glyph({
        name = v and "circle-filled" or "circle",
        size = 13,
        color = bucket(v),
        flexGrow = 1,
      }))
    end
    table.insert(children, ui.row({ align = "center" }, labels))
    table.insert(children, ui.row({ align = "center" }, weekDots))
  end

  if data.error and data.error ~= "" then
    table.insert(children, ui.label({ text = data.error, fontSize = 11, color = "error", maxLines = 2 }))
  end

  desktopWidget.render(ui.column({
    width = width,
    height = height,
    padding = 20,
    gap = 10,
    fill = "surface",
    border = accent and bucket(today) or "outline",
    borderWidth = 1,
    radius = 22,
    align = "stretch",
  }, children))
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

function update()
  data = noctalia.state.get("feeling") or {}
  render()
end

noctalia.setUpdateInterval(60000)
data = noctalia.state.get("feeling") or {}
render()
noctalia.state.watch("feeling", function(next)
  data = type(next) == "table" and next or {}
  render()
end)
