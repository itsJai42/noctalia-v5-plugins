--!nonstrict
local updates = {}
local loading = false

local function command()
  local parts = { "(" .. noctalia.getConfig("system_cmd") .. ")" , "(" .. noctalia.getConfig("aur_cmd") .. ")" }
  if noctalia.getConfig("include_flatpak") then
    table.insert(parts, "flatpak remote-ls --updates --columns=application 2>/dev/null")
  end
  return table.concat(parts, "; ")
end

local function refresh()
  if loading then return end
  loading = true
  barWidget.setGlyph("loader")
  noctalia.runAsync(command(), function(result)
    loading = false
    updates = {}
    for line in result.stdout:gmatch("[^\r\n]+") do table.insert(updates, line) end
    barWidget.setGlyph(#updates > 0 and "arrow-big-down-lines" or "check")
    barWidget.setText(tostring(#updates))
    barWidget.setTooltip(#updates == 0 and noctalia.tr("up_to_date") or table.concat(updates, "\n"))
  end, 60000)
end

function update()
  noctalia.setUpdateInterval(noctalia.getConfig("refresh_minutes") * 60000)
  refresh()
end

function onClick() noctalia.togglePanel("noctalia/arch-updater:updates-panel") end
function onMiddleClick() refresh() end
function onIpc(event) if event == "refresh" then refresh() elseif event == "update" then noctalia.runInTerminal(noctalia.getConfig("update_cmd")) end end
