--!nonstrict
local prompt = ""
local response = ""
local busy = false
local render
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end

render = function()
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between", align = "center" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.scroll({ flexGrow = 1 }, { ui.label({ text = response ~= "" and response or noctalia.tr("empty"), color = response ~= "" and "on_surface" or "on_surface_variant" }) }),
    ui.input({ key = "prompt", placeholder = noctalia.tr("placeholder"), onChange = "onPromptChanged", onSubmit = "sendPrompt", enabled = not busy }),
    ui.button({ text = busy and noctalia.tr("running") or noctalia.tr("send"), glyph = "send", variant = "primary", onClick = "sendPrompt", enabled = not busy and prompt ~= "" }),
  }))
end

function onPromptChanged(value) prompt = value; render() end
function sendPrompt(value)
  if busy then return end
  local text = type(value) == "string" and value ~= "" and value or prompt
  if text == "" then return end
  busy = true; response = noctalia.tr("running"); render()
  local command = quote(noctalia.getConfig("binary")) .. " -p --output-format text --permission-mode " .. quote(noctalia.getConfig("permission_mode"))
  local model = noctalia.getConfig("model")
  if model ~= "" then command ..= " --model " .. quote(model) end
  command ..= " " .. quote(text)
  local directory = noctalia.getConfig("working_directory")
  if directory ~= "" then command = "cd " .. quote(noctalia.expandPath(directory)) .. " && " .. command end
  noctalia.runAsync(command, function(result)
    busy = false
    response = result.exitCode == 0 and result.stdout or (result.stderr ~= "" and result.stderr or noctalia.tr("failed"))
    render()
  end, 60000)
end
function closePanel() panel.close() end
function onOpen() render() end
