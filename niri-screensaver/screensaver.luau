--!nonstrict
local running = false
local function refresh()
  noctalia.runAsync("niri-screensaver-launch is-running", function(result)
    running = result.exitCode == 0
    barWidget.setGlyph(running and "device-desktop-x" or "device-desktop-pause")
    barWidget.setTooltip(running and noctalia.tr("running") or noctalia.tr("stopped"))
  end)
end
function update() noctalia.setUpdateInterval(3000); refresh() end
function onClick() noctalia.runAsync(running and noctalia.getConfig("kill_command") or noctalia.getConfig("launch_command"), function() refresh() end) end
function onIpc(event) if event == "launch" then noctalia.runAsync(noctalia.getConfig("launch_command")) elseif event == "kill" then noctalia.runAsync(noctalia.getConfig("kill_command")) end end
