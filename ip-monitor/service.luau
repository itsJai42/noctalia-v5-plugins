--!nonstrict
local busy = false
local function refresh()
  if busy then return end
  busy = true
  noctalia.http({ url = "https://ipapi.co/json/" }, function(response)
    busy = false
    local data = response.ok and noctalia.json.decode(response.body) or nil
    noctalia.state.set("ip", type(data) == "table" and data or { error = noctalia.tr("fetch_failed") })
  end)
end
noctalia.setUpdateInterval(noctalia.getConfig("refresh_seconds") * 1000)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end
refresh()
