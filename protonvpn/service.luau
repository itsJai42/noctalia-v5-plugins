--!nonstrict
local busy = false
local function refresh()
  if busy then return end
  busy = true
  noctalia.runAsync("protonvpn status", function(result)
    busy = false
    local output = result.stdout ~= "" and result.stdout or result.stderr
    local connected = result.exitCode == 0 and not output:lower():find("disconnected", 1, true)
    noctalia.state.set("proton", { connected = connected, status = noctalia.string.trim(output), available = result.exitCode == 0 or output ~= "" })
  end)
end
noctalia.setUpdateInterval(noctalia.getConfig("poll_seconds") * 1000)
noctalia.state.watch("proton-command", function(command)
  local action = type(command) == "table" and command.action or command
  if action == "connect" then noctalia.runAsync("protonvpn connect --fastest", function() refresh() end)
  elseif action == "disconnect" then noctalia.runAsync("protonvpn disconnect", function() refresh() end)
  elseif action == "secure-core" then noctalia.runAsync("protonvpn connect --secure-core", function() refresh() end)
  elseif action == "p2p" then noctalia.runAsync("protonvpn connect --p2p", function() refresh() end) end
end)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() elseif event then noctalia.state.set("proton-command", event) end end
refresh()
