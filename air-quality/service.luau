--!nonstrict
local busy = false

local function publishError(message) noctalia.state.set("air", { error = message }) end

local function fetchAt(latitude, longitude)
  local url = "https://air-quality-api.open-meteo.com/v1/air-quality?current=us_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,carbon_monoxide,sulphur_dioxide&latitude="
    .. noctalia.string.urlEncode(tostring(latitude)) .. "&longitude=" .. noctalia.string.urlEncode(tostring(longitude))
  noctalia.http({ url = url }, function(response)
    busy = false
    local data = response.ok and noctalia.json.decode(response.body) or nil
    if type(data) ~= "table" or type(data.current) ~= "table" then publishError(noctalia.tr("fetch_failed")); return end
    local current = data.current
    current.latitude = latitude
    current.longitude = longitude
    noctalia.state.set("air", current)
  end)
end

local function refresh()
  if busy then return end
  busy = true
  local lat, lon = noctalia.getConfig("latitude"), noctalia.getConfig("longitude")
  if lat ~= "" and lon ~= "" then fetchAt(lat, lon); return end
  noctalia.http({ url = "https://ipapi.co/json/" }, function(response)
    local geo = response.ok and noctalia.json.decode(response.body) or nil
    if type(geo) ~= "table" or not geo.latitude or not geo.longitude then busy = false; publishError(noctalia.tr("location_failed")); return end
    fetchAt(geo.latitude, geo.longitude)
  end)
end

noctalia.setUpdateInterval(noctalia.getConfig("refresh_minutes") * 60000)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end
noctalia.state.watch("air-refresh", function() refresh() end)
refresh()
