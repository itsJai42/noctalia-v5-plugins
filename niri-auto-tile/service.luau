--!nonstrict
local running = false
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
local function publish() noctalia.state.set("auto-tile-running", running) end
local function stop()
  local script = (noctalia.pluginDir() or "") .. "/auto-tile.py"
  noctalia.runAsync("pkill -f " .. quote(script) .. " 2>/dev/null || true")
  running = false
  publish()
end
local function start()
  if running or not noctalia.getConfig("enabled") then return end
  local script = (noctalia.pluginDir() or "") .. "/auto-tile.py"
  local command = "python3 " .. quote(script) .. " --max-visible " .. tostring(noctalia.getConfig("max_visible"))
  if noctalia.getConfig("only_at_max") then command ..= " --only-at-max" end
  running = noctalia.runStream(command, function(line) if line ~= "" then noctalia.log("niri-auto-tile: " .. line) end end)
  publish()
end
noctalia.state.watch("auto-tile-command", function(command)
  local action = type(command) == "table" and command.action or command
  if action == "start" then start() elseif action == "stop" then stop() end
end)
function onIpc(event) if event == "start" then start() elseif event == "stop" then stop() elseif event == "restart" then stop(); start() end end
if noctalia.getConfig("enabled") then start() else publish() end
