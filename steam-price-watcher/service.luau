--!nonstrict
local generation = 0
local notified = {}
local function refresh()
  generation += 1
  local current = generation
  local entries = noctalia.getConfig("watchlist") or {}
  local pending = #entries
  local games = {}
  if pending == 0 then noctalia.state.set("prices", { games = {}, reached = 0 }); return end
  local function finish()
    pending -= 1
    if pending > 0 or current ~= generation then return end
    local reached = 0
    for _, game in ipairs(games) do
      if game.reached then
        reached += 1
        if not notified[game.appid] then noctalia.notify(noctalia.tr("title"), noctalia.tr("reached", { name = game.name, price = game.price })); notified[game.appid] = true end
      else notified[game.appid] = nil end
    end
    noctalia.state.set("prices", { games = games, reached = reached })
  end
  for _, entry in ipairs(entries) do
    local appid, target, name = entry:match("^(%d+):([%d%.]+):?(.*)$")
    if not appid then pending -= 1 else
      local url = "https://store.steampowered.com/api/appdetails?appids=" .. appid .. "&cc=" .. noctalia.string.urlEncode(noctalia.getConfig("country_code"))
      noctalia.http({ url = url }, function(response)
        local body = response.ok and noctalia.json.decode(response.body) or nil
        local app = type(body) == "table" and body[appid] or nil
        local info = type(app) == "table" and app.data or nil
        local price = type(info) == "table" and info.price_overview or nil
        if type(price) == "table" then table.insert(games, { appid = appid, name = name ~= "" and name or info.name or appid, price = price.final / 100, target = tonumber(target), reached = price.final / 100 <= tonumber(target) }) end
        finish()
      end)
    end
  end
  if pending == 0 then noctalia.state.set("prices", { games = {}, reached = 0 }) end
end
noctalia.setUpdateInterval(noctalia.getConfig("check_minutes") * 60000)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end
refresh()
