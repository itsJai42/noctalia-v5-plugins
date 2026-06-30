--!nonstrict
local profiles = {}
local slots = {}
local draft = ""
local status = ""
local render
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
local function profilesDir() return noctalia.expandPath(noctalia.getConfig("profiles_directory")) end
local function stateDir() return noctalia.getenv("XDG_STATE_HOME") or ((noctalia.getenv("HOME") or "") .. "/.local/state") end
local function settingsPath() return stateDir() .. "/noctalia/settings.toml" end

local function load()
  profiles = {}
  for _, name in ipairs(noctalia.listDir(profilesDir()) or {}) do
    if noctalia.fileExists(profilesDir() .. "/" .. name .. "/settings.toml") then table.insert(profiles, name) end
  end
  table.sort(profiles)
end

local function apply(index)
  local name = slots[index]
  if not name then return end
  local source = profilesDir() .. "/" .. name .. "/settings.toml"
  local target = settingsPath()
  local command = "cp " .. quote(target) .. " " .. quote(target .. ".before-profile") .. " && cp " .. quote(source) .. " " .. quote(target) .. " && noctalia msg config reload"
  noctalia.runAsync(command, function(result)
    status = result.exitCode == 0 and noctalia.tr("applied", { name = name }) or noctalia.tr("apply_failed")
    render()
  end)
end

render = function()
  slots = {}
  local rows = {}
  for i, name in ipairs(profiles) do
    if i > 20 then break end
    slots[i] = name
    table.insert(rows, ui.button({ text = name, glyph = "wand", onClick = "apply" .. tostring(i) }))
  end
  if #rows == 0 then table.insert(rows, ui.label({ text = noctalia.tr("empty"), color = "on_surface_variant" })) end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between" }, { ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }), ui.button({ glyph = "close", onClick = "closePanel" }) }),
    ui.label({ text = status, color = "on_surface_variant" }),
    ui.scroll({ flexGrow = 1, gap = 8 }, rows),
    ui.input({ key = "profile-name", placeholder = noctalia.tr("placeholder"), onChange = "onDraft", onSubmit = "saveProfile" }),
    ui.button({ text = noctalia.tr("save"), glyph = "device-floppy", variant = "primary", onClick = "saveProfile", enabled = draft ~= "" }),
  }))
end

function onDraft(value) draft = value end
function saveProfile(value)
  local name = noctalia.string.trim(type(value) == "string" and value ~= "" and value or draft)
  if name == "" or not name:match("^[%w _%-]+$") then status = noctalia.tr("invalid_name"); render(); return end
  local destination = profilesDir() .. "/" .. name
  noctalia.runAsync("mkdir -p " .. quote(destination) .. " && cp " .. quote(settingsPath()) .. " " .. quote(destination .. "/settings.toml"), function(result)
    status = result.exitCode == 0 and noctalia.tr("saved", { name = name }) or noctalia.tr("save_failed")
    if result.exitCode == 0 then draft = ""; load() end
    render()
  end)
end
function closePanel() panel.close() end
function onOpen() load(); render() end
function apply1() apply(1) end
function apply2() apply(2) end
function apply3() apply(3) end
function apply4() apply(4) end
function apply5() apply(5) end
function apply6() apply(6) end
function apply7() apply(7) end
function apply8() apply(8) end
function apply9() apply(9) end
function apply10() apply(10) end
function apply11() apply(11) end
function apply12() apply(12) end
function apply13() apply(13) end
function apply14() apply(14) end
function apply15() apply(15) end
function apply16() apply(16) end
function apply17() apply(17) end
function apply18() apply(18) end
function apply19() apply(19) end
function apply20() apply(20) end
