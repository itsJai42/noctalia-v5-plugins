--!nonstrict
local stateKey = "hotkeys-cheatsheet"
local commandKey = "hotkeys-cheatsheet-command"
local data = {}
local searchText = ""
local sourceDraft = ""
local status = ""
local tabIds = {}
local pinSlots = {}

local builtin = { niri = true, noctalia = true, kitty = true }
local validKind = { auto = true, niri = true, noctalia = true, kitty = true, toml = true, json = true, kdl = true }

local function trim(value)
  return noctalia.string.trim(tostring(value or ""))
end

local function request(command)
  command.nonce = os.clock()
  noctalia.state.set(commandKey, command)
end

local function sets()
  return type(data.sets) == "table" and data.sets or {}
end

local function selectedSet()
  for _, set in ipairs(sets()) do if set.id == data.selected then return set end end
  return sets()[1]
end

local function setSelected(id)
  data.selected = id
  request({ action = "select", id = id })
  render(data)
end

local function basename(path)
  local cleaned = tostring(path or ""):gsub("/+$", "")
  return cleaned:match("([^/]+)$") or cleaned
end

local function splitSpec(text)
  local parts = {}
  for piece in (text .. "|"):gmatch("(.-)|") do table.insert(parts, trim(piece)) end
  local name, kind, path = "", "auto", ""
  if #parts == 1 then
    path = parts[1]
    name = basename(path)
  elseif #parts == 2 then
    name, path = parts[1], parts[2]
  else
    name, kind, path = parts[1], parts[2], parts[3]
    for i = 4, #parts do path = path .. "|" .. parts[i] end
  end
  if name == "" then name = basename(path) end
  if not validKind[kind] then kind = "auto" end
  return name, kind, path
end

local function compact(text)
  return tostring(text or ""):lower():gsub("[%s%p]+", "")
end

local function fuzzyContains(needle, hay)
  needle = compact(needle)
  hay = compact(hay)
  if needle == "" then return true end
  if hay:find(needle, 1, true) then return true end
  local index = 1
  for i = 1, #needle do
    local char = needle:sub(i, i)
    index = hay:find(char, index, true)
    if not index then return false end
    index = index + 1
  end
  return true
end

local function itemMatches(item, needle)
  if needle == "" then return true end
  local hay = table.concat({ tostring(item.keys or ""), tostring(item.action or ""), tostring(item.group or ""), tostring(item.description or "") }, " "):lower()
  return hay:find(needle, 1, true) ~= nil or fuzzyContains(needle, hay)
end

local function togglePinSlot(index)
  local slot = pinSlots[index]
  if slot then request({ action = "pin", id = slot.setId, pin = slot.pinId }) end
end

local function heading(text, pinned)
  return ui.row({ align = "center", gap = 6 }, {
    ui.glyph({ name = pinned and "star-filled" or "folder", size = 14, color = pinned and "primary" or "on_surface_variant" }),
    ui.label({ text = text, fontSize = pinned and 14 or 13, fontWeight = "bold", color = pinned and "primary" or "on_surface_variant", maxLines = 1 }),
  })
end

local function keyRow(item, setId)
  local slotIndex = 0
  if item.pin_id and #pinSlots < 200 then
    table.insert(pinSlots, { setId = setId, pinId = item.pin_id })
    slotIndex = #pinSlots
  end
  local description = tostring(item.description or "")
  local firstLine = {
    ui.label({ text = tostring(item.keys or ""), fontSize = 13, fontWeight = "bold", color = "primary", maxLines = 1 }),
    ui.label({ text = tostring(item.action or ""), fontSize = 13, fontWeight = "medium", flexGrow = 1, maxLines = 1 }),
  }
  if slotIndex > 0 then
    table.insert(firstLine, ui.button({ glyph = item.pinned and "star-filled" or "star", variant = "ghost", onClick = "togglePin" .. tostring(slotIndex) }))
  end
  local children = { ui.row({ gap = 10, align = "center" }, firstLine) }
  if description ~= "" then
    table.insert(children, ui.label({ text = description, fontSize = 11, color = "on_surface_variant", maxLines = 2 }))
  end
  return ui.column({ gap = 4, padding = 6, align = "stretch" }, children)
end

local function appendRows(rows, set, needle, pinnedOnly)
  local lastGroup = ""
  local found = 0
  for _, item in ipairs(set.items or {}) do
    if itemMatches(item, needle) and ((item.pinned == true) == pinnedOnly) then
      if pinnedOnly then
        table.insert(rows, keyRow(item, set.id))
      else
        local group = tostring(item.group or "")
        if group ~= "" and group ~= lastGroup then
          table.insert(rows, heading(group, false))
          lastGroup = group
        end
        table.insert(rows, keyRow(item, set.id))
      end
      found = found + 1
    end
  end
  return found
end

local function buildItems(set)
  pinSlots = {}
  local rows = {}
  if not set then
    table.insert(rows, ui.label({ text = noctalia.tr("loading"), color = "on_surface_variant" }))
    return rows
  end
  if not set.enabled then
    table.insert(rows, ui.label({ text = noctalia.tr("disabled"), color = "on_surface_variant" }))
    return rows
  end
  if tonumber(set.count) == 0 then
    table.insert(rows, ui.label({ text = set.error or noctalia.tr("empty"), color = "on_surface_variant", maxLines = 4 }))
    return rows
  end
  local needle = trim(searchText):lower()
  local found = 0
  if tonumber(set.pinned_count) and tonumber(set.pinned_count) > 0 then
    table.insert(rows, heading(noctalia.tr("pinned"), true))
    found = found + appendRows(rows, set, needle, true)
    table.insert(rows, ui.separator({ color = "outline", opacity = 0.35 }))
  end
  found = found + appendRows(rows, set, needle, false)
  if found == 0 then table.insert(rows, ui.label({ text = noctalia.tr("no_matches"), color = "on_surface_variant" })) end
  return rows
end

local function selectTab(index)
  local id = tabIds[index]
  if id then setSelected(id) end
end

local function setTabs()
  tabIds = {}
  local tabs = {}
  for i, set in ipairs(sets()) do
    if i > 20 then break end
    tabIds[i] = tostring(set.id or "")
    local active = set.id == data.selected
    local text = tostring(set.name or set.id or "?") .. " " .. tostring(set.count or 0)
    if not set.enabled then text = "○ " .. tostring(set.name or set.id or "?") end
    table.insert(tabs, ui.button({
      text = text,
      glyph = set.enabled and "keyboard" or "circle-off",
      variant = active and "primary" or "ghost",
      onClick = "selectSet" .. tostring(i),
    }))
  end
  if #tabs == 0 then table.insert(tabs, ui.label({ text = noctalia.tr("loading"), color = "on_surface_variant" })) end
  return tabs
end

function render(nextData)
  data = type(nextData) == "table" and nextData or {}
  local set = selectedSet()
  local count = set and tonumber(set.count) or 0
  local pathText = set and type(set.paths) == "table" and table.concat(set.paths, "\n") or ""
  local rows = buildItems(set)
  local message = data.error or status

  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ justify = "space_between", align = "center", gap = 8 }, {
      ui.glyph({ name = data.error and "alert-circle" or "keyboard", size = 20, color = data.error and "error" or "primary" }),
      ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "refresh", variant = "ghost", onClick = "refreshHotkeys" }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "closePanel" }),
    }),
    ui.label({ text = message, color = data.error and "error" or "on_surface_variant", maxLines = 2, visible = message ~= "" }),
    ui.row({ gap = 8, align = "center" }, setTabs()),
    ui.box({ fill = "surface", radius = 12 }, {
      ui.column({ gap = 8, padding = 10, align = "stretch" }, {
        ui.row({ gap = 8, align = "center" }, {
          ui.label({ text = set and tostring(set.name or set.id) or noctalia.tr("loading"), fontSize = 14, fontWeight = "bold", flexGrow = 1, maxLines = 1 }),
          ui.label({ text = noctalia.tr("count", { count = count }), color = "on_surface_variant" }),
          ui.button({ text = set and set.enabled and noctalia.tr("disable") or noctalia.tr("enable"), glyph = set and set.enabled and "eye-off" or "eye", onClick = "toggleActive", enabled = set ~= nil }),
          ui.button({ text = noctalia.tr("remove"), glyph = "trash", onClick = "removeActive", enabled = set ~= nil and not builtin[set.id] }),
        }),
        ui.label({ text = pathText, fontSize = 10, color = "on_surface_variant", maxLines = 2, visible = pathText ~= "" }),
      })
    }),
    ui.input({ key = "hotkey-search", placeholder = noctalia.tr("search"), onChange = "onSearch" }),
    ui.scroll({ flexGrow = 1, gap = 8 }, rows),
    ui.separator({ color = "outline", opacity = 0.35 }),
    ui.column({ gap = 8, align = "stretch" }, {
      ui.row({ align = "center", gap = 8 }, {
        ui.label({ text = noctalia.tr("import_title"), fontSize = 13, fontWeight = "bold", flexGrow = 1 }),
        ui.button({ text = "TOML", variant = "ghost", onClick = "copyTomlSample" }),
        ui.button({ text = "JSON", variant = "ghost", onClick = "copyJsonSample" }),
      }),
      ui.label({ text = noctalia.tr("import_desc"), fontSize = 11, color = "on_surface_variant", maxLines = 2 }),
      ui.input({ key = "hotkey-source", placeholder = noctalia.tr("source_placeholder"), onChange = "onSourceDraft", onSubmit = "addSource" }),
      ui.button({ text = noctalia.tr("add_source"), glyph = "plus", variant = "primary", onClick = "addSource", enabled = trim(sourceDraft) ~= "" }),
    }),
  }))
end

function onSearch(value)
  searchText = tostring(value or "")
  render(data)
end

function onSourceDraft(value)
  sourceDraft = tostring(value or "")
  render(data)
end

function addSource(value)
  local text = trim(type(value) == "string" and value ~= "" and value or sourceDraft)
  local name, kind, path = splitSpec(text)
  if path == "" then
    status = noctalia.tr("bad_spec")
    render(data)
    return
  end
  status = noctalia.tr("adding", { name = name })
  request({ action = "add", name = name, kind = kind, path = path })
  render(data)
end

function toggleActive()
  local set = selectedSet()
  if not set then return end
  status = set.enabled and noctalia.tr("disabled_status", { name = set.name }) or noctalia.tr("enabled_status", { name = set.name })
  request({ action = "toggle", id = set.id })
  render(data)
end

function removeActive()
  local set = selectedSet()
  if not set or builtin[set.id] then return end
  status = noctalia.tr("removed", { name = set.name })
  request({ action = "remove", id = set.id })
  render(data)
end

function refreshHotkeys()
  status = noctalia.tr("refreshing")
  request({ action = "refresh" })
  render(data)
end

function copyTomlSample()
  local sample = '[[hotkey]]\nkeys = "Ctrl+K"\naction = "Open command palette"\ngroup = "General"\ndescription = "Example TOML shortcut"\n'
  noctalia.copyToClipboard(sample, "text/plain")
  noctalia.notify(noctalia.tr("title"), noctalia.tr("copied_sample"))
end

function copyJsonSample()
  local sample = '[{"keys":"Ctrl+K","action":"Open command palette","group":"General","description":"Example JSON shortcut"}]\n'
  noctalia.copyToClipboard(sample, "text/plain")
  noctalia.notify(noctalia.tr("title"), noctalia.tr("copied_sample"))
end

function togglePin1() togglePinSlot(1) end
function togglePin2() togglePinSlot(2) end
function togglePin3() togglePinSlot(3) end
function togglePin4() togglePinSlot(4) end
function togglePin5() togglePinSlot(5) end
function togglePin6() togglePinSlot(6) end
function togglePin7() togglePinSlot(7) end
function togglePin8() togglePinSlot(8) end
function togglePin9() togglePinSlot(9) end
function togglePin10() togglePinSlot(10) end
function togglePin11() togglePinSlot(11) end
function togglePin12() togglePinSlot(12) end
function togglePin13() togglePinSlot(13) end
function togglePin14() togglePinSlot(14) end
function togglePin15() togglePinSlot(15) end
function togglePin16() togglePinSlot(16) end
function togglePin17() togglePinSlot(17) end
function togglePin18() togglePinSlot(18) end
function togglePin19() togglePinSlot(19) end
function togglePin20() togglePinSlot(20) end
function togglePin21() togglePinSlot(21) end
function togglePin22() togglePinSlot(22) end
function togglePin23() togglePinSlot(23) end
function togglePin24() togglePinSlot(24) end
function togglePin25() togglePinSlot(25) end
function togglePin26() togglePinSlot(26) end
function togglePin27() togglePinSlot(27) end
function togglePin28() togglePinSlot(28) end
function togglePin29() togglePinSlot(29) end
function togglePin30() togglePinSlot(30) end
function togglePin31() togglePinSlot(31) end
function togglePin32() togglePinSlot(32) end
function togglePin33() togglePinSlot(33) end
function togglePin34() togglePinSlot(34) end
function togglePin35() togglePinSlot(35) end
function togglePin36() togglePinSlot(36) end
function togglePin37() togglePinSlot(37) end
function togglePin38() togglePinSlot(38) end
function togglePin39() togglePinSlot(39) end
function togglePin40() togglePinSlot(40) end
function togglePin41() togglePinSlot(41) end
function togglePin42() togglePinSlot(42) end
function togglePin43() togglePinSlot(43) end
function togglePin44() togglePinSlot(44) end
function togglePin45() togglePinSlot(45) end
function togglePin46() togglePinSlot(46) end
function togglePin47() togglePinSlot(47) end
function togglePin48() togglePinSlot(48) end
function togglePin49() togglePinSlot(49) end
function togglePin50() togglePinSlot(50) end
function togglePin51() togglePinSlot(51) end
function togglePin52() togglePinSlot(52) end
function togglePin53() togglePinSlot(53) end
function togglePin54() togglePinSlot(54) end
function togglePin55() togglePinSlot(55) end
function togglePin56() togglePinSlot(56) end
function togglePin57() togglePinSlot(57) end
function togglePin58() togglePinSlot(58) end
function togglePin59() togglePinSlot(59) end
function togglePin60() togglePinSlot(60) end
function togglePin61() togglePinSlot(61) end
function togglePin62() togglePinSlot(62) end
function togglePin63() togglePinSlot(63) end
function togglePin64() togglePinSlot(64) end
function togglePin65() togglePinSlot(65) end
function togglePin66() togglePinSlot(66) end
function togglePin67() togglePinSlot(67) end
function togglePin68() togglePinSlot(68) end
function togglePin69() togglePinSlot(69) end
function togglePin70() togglePinSlot(70) end
function togglePin71() togglePinSlot(71) end
function togglePin72() togglePinSlot(72) end
function togglePin73() togglePinSlot(73) end
function togglePin74() togglePinSlot(74) end
function togglePin75() togglePinSlot(75) end
function togglePin76() togglePinSlot(76) end
function togglePin77() togglePinSlot(77) end
function togglePin78() togglePinSlot(78) end
function togglePin79() togglePinSlot(79) end
function togglePin80() togglePinSlot(80) end
function togglePin81() togglePinSlot(81) end
function togglePin82() togglePinSlot(82) end
function togglePin83() togglePinSlot(83) end
function togglePin84() togglePinSlot(84) end
function togglePin85() togglePinSlot(85) end
function togglePin86() togglePinSlot(86) end
function togglePin87() togglePinSlot(87) end
function togglePin88() togglePinSlot(88) end
function togglePin89() togglePinSlot(89) end
function togglePin90() togglePinSlot(90) end
function togglePin91() togglePinSlot(91) end
function togglePin92() togglePinSlot(92) end
function togglePin93() togglePinSlot(93) end
function togglePin94() togglePinSlot(94) end
function togglePin95() togglePinSlot(95) end
function togglePin96() togglePinSlot(96) end
function togglePin97() togglePinSlot(97) end
function togglePin98() togglePinSlot(98) end
function togglePin99() togglePinSlot(99) end
function togglePin100() togglePinSlot(100) end
function togglePin101() togglePinSlot(101) end
function togglePin102() togglePinSlot(102) end
function togglePin103() togglePinSlot(103) end
function togglePin104() togglePinSlot(104) end
function togglePin105() togglePinSlot(105) end
function togglePin106() togglePinSlot(106) end
function togglePin107() togglePinSlot(107) end
function togglePin108() togglePinSlot(108) end
function togglePin109() togglePinSlot(109) end
function togglePin110() togglePinSlot(110) end
function togglePin111() togglePinSlot(111) end
function togglePin112() togglePinSlot(112) end
function togglePin113() togglePinSlot(113) end
function togglePin114() togglePinSlot(114) end
function togglePin115() togglePinSlot(115) end
function togglePin116() togglePinSlot(116) end
function togglePin117() togglePinSlot(117) end
function togglePin118() togglePinSlot(118) end
function togglePin119() togglePinSlot(119) end
function togglePin120() togglePinSlot(120) end
function togglePin121() togglePinSlot(121) end
function togglePin122() togglePinSlot(122) end
function togglePin123() togglePinSlot(123) end
function togglePin124() togglePinSlot(124) end
function togglePin125() togglePinSlot(125) end
function togglePin126() togglePinSlot(126) end
function togglePin127() togglePinSlot(127) end
function togglePin128() togglePinSlot(128) end
function togglePin129() togglePinSlot(129) end
function togglePin130() togglePinSlot(130) end
function togglePin131() togglePinSlot(131) end
function togglePin132() togglePinSlot(132) end
function togglePin133() togglePinSlot(133) end
function togglePin134() togglePinSlot(134) end
function togglePin135() togglePinSlot(135) end
function togglePin136() togglePinSlot(136) end
function togglePin137() togglePinSlot(137) end
function togglePin138() togglePinSlot(138) end
function togglePin139() togglePinSlot(139) end
function togglePin140() togglePinSlot(140) end
function togglePin141() togglePinSlot(141) end
function togglePin142() togglePinSlot(142) end
function togglePin143() togglePinSlot(143) end
function togglePin144() togglePinSlot(144) end
function togglePin145() togglePinSlot(145) end
function togglePin146() togglePinSlot(146) end
function togglePin147() togglePinSlot(147) end
function togglePin148() togglePinSlot(148) end
function togglePin149() togglePinSlot(149) end
function togglePin150() togglePinSlot(150) end
function togglePin151() togglePinSlot(151) end
function togglePin152() togglePinSlot(152) end
function togglePin153() togglePinSlot(153) end
function togglePin154() togglePinSlot(154) end
function togglePin155() togglePinSlot(155) end
function togglePin156() togglePinSlot(156) end
function togglePin157() togglePinSlot(157) end
function togglePin158() togglePinSlot(158) end
function togglePin159() togglePinSlot(159) end
function togglePin160() togglePinSlot(160) end
function togglePin161() togglePinSlot(161) end
function togglePin162() togglePinSlot(162) end
function togglePin163() togglePinSlot(163) end
function togglePin164() togglePinSlot(164) end
function togglePin165() togglePinSlot(165) end
function togglePin166() togglePinSlot(166) end
function togglePin167() togglePinSlot(167) end
function togglePin168() togglePinSlot(168) end
function togglePin169() togglePinSlot(169) end
function togglePin170() togglePinSlot(170) end
function togglePin171() togglePinSlot(171) end
function togglePin172() togglePinSlot(172) end
function togglePin173() togglePinSlot(173) end
function togglePin174() togglePinSlot(174) end
function togglePin175() togglePinSlot(175) end
function togglePin176() togglePinSlot(176) end
function togglePin177() togglePinSlot(177) end
function togglePin178() togglePinSlot(178) end
function togglePin179() togglePinSlot(179) end
function togglePin180() togglePinSlot(180) end
function togglePin181() togglePinSlot(181) end
function togglePin182() togglePinSlot(182) end
function togglePin183() togglePinSlot(183) end
function togglePin184() togglePinSlot(184) end
function togglePin185() togglePinSlot(185) end
function togglePin186() togglePinSlot(186) end
function togglePin187() togglePinSlot(187) end
function togglePin188() togglePinSlot(188) end
function togglePin189() togglePinSlot(189) end
function togglePin190() togglePinSlot(190) end
function togglePin191() togglePinSlot(191) end
function togglePin192() togglePinSlot(192) end
function togglePin193() togglePinSlot(193) end
function togglePin194() togglePinSlot(194) end
function togglePin195() togglePinSlot(195) end
function togglePin196() togglePinSlot(196) end
function togglePin197() togglePinSlot(197) end
function togglePin198() togglePinSlot(198) end
function togglePin199() togglePinSlot(199) end
function togglePin200() togglePinSlot(200) end
function closePanel() panel.close() end
function selectSet1() selectTab(1) end
function selectSet2() selectTab(2) end
function selectSet3() selectTab(3) end
function selectSet4() selectTab(4) end
function selectSet5() selectTab(5) end
function selectSet6() selectTab(6) end
function selectSet7() selectTab(7) end
function selectSet8() selectTab(8) end
function selectSet9() selectTab(9) end
function selectSet10() selectTab(10) end
function selectSet11() selectTab(11) end
function selectSet12() selectTab(12) end
function selectSet13() selectTab(13) end
function selectSet14() selectTab(14) end
function selectSet15() selectTab(15) end
function selectSet16() selectTab(16) end
function selectSet17() selectTab(17) end
function selectSet18() selectTab(18) end
function selectSet19() selectTab(19) end
function selectSet20() selectTab(20) end
function onOpen() render(noctalia.state.get(stateKey)) end
function update() render(noctalia.state.get(stateKey)) end

render(noctalia.state.get(stateKey))
noctalia.state.watch(stateKey, function(next)
  status = ""
  render(next)
end)
