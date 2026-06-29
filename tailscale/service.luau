--!nonstrict
local busy = false
local function refresh()
  if busy then return end
  busy = true
  noctalia.runAsync("tailscale status --json", function(result)
    busy = false
    local data = result.exitCode == 0 and noctalia.json.decode(result.stdout) or nil
    if type(data) ~= "table" then noctalia.state.set("tailscale", { error = noctalia.tr("unavailable") }); return end
    local peers = {}
    for _, peer in pairs(type(data.Peer) == "table" and data.Peer or {}) do
      table.insert(peers, { name = peer.HostName or peer.DNSName or "?", online = peer.Online == true, ip = type(peer.TailscaleIPs) == "table" and peer.TailscaleIPs[1] or "" })
    end
    table.sort(peers, function(a, b) return a.name < b.name end)
    local self = type(data.Self) == "table" and data.Self or {}
    noctalia.state.set("tailscale", { running = data.BackendState == "Running", state = data.BackendState, ip = type(self.TailscaleIPs) == "table" and self.TailscaleIPs[1] or "", peers = peers })
  end)
end
noctalia.setUpdateInterval(noctalia.getConfig("poll_seconds") * 1000)
noctalia.state.watch("tailscale-command", function(command)
  local action = type(command) == "table" and command.action or command
  if action == "up" or action == "down" then noctalia.runAsync("tailscale " .. action, function() refresh() end) end
end)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() elseif event == "up" or event == "down" then noctalia.state.set("tailscale-command", event) end end
refresh()
