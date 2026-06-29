--!nonstrict
local expression = ""
local result = ""
local render
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
render = function()
  panel.render(ui.column({ flexGrow = 1, gap = 14, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.input({ key = "expression", placeholder = noctalia.tr("placeholder"), onChange = "onExpression", onSubmit = "calculate" }),
    ui.label({ text = result ~= "" and result or "=", fontSize = 28, fontWeight = "bold", color = "primary" }),
    ui.button({ text = noctalia.tr("calculate"), glyph = "equal", variant = "primary", onClick = "calculate" }),
  }))
end
function onExpression(value) expression = value end
function calculate(value)
  local text = type(value) == "string" and value ~= "" and value or expression
  if text == "" then return end
  noctalia.runAsync("qalc -t " .. quote(text), function(output) result = output.exitCode == 0 and noctalia.string.trim(output.stdout) or noctalia.string.trim(output.stderr); render() end)
end
function closePanel() panel.close() end
function onOpen() render() end
