--!nonstrict
-- Headless service: reads `feeling export`, derives today + last-7-days,
-- publishes state["feeling"]. Only writer of mood data (via `feeling N -y`).

local function bin()
  local b = noctalia.getConfig("binary_path")
  return (type(b) == "string" and noctalia.string.trim(b) ~= "") and b or "feeling"
end

local function refreshMs()
  return math.max(1, tonumber(noctalia.getConfig("refresh_minutes")) or 5) * 60000
end

-- "YYYY-MM-DD" for an os.time() value
local function dayKey(t) return os.date("%Y-%m-%d", t) end

-- Parse `feeling export` CSV into a date->value map.
local function parseCsv(text)
  local map = {}
  for line in tostring(text):gmatch("[^\r\n]+") do
    local date, val = line:match("^(%d%d%d%d%-%d%d%-%d%d),(%d+)$")
    if date and val then map[date] = tonumber(val) end
  end
  return map
end

-- Build the published payload from a date->value map.
local function buildState(map, errorMessage)
  local now = os.time()
  local todayKey = dayKey(now)
  local week, days = {}, {}
  for i = 6, 0, -1 do
    local t = now - i * 86400
    table.insert(week, map[dayKey(t)])      -- value or nil
    table.insert(days, os.date("%a", t))    -- "Mon".."Sun"
  end
  return {
    today = map[todayKey],
    week = week,
    days = days,
    error = errorMessage or "",
  }
end

local lastRequestAt = 0

local function publishError(msg)
  noctalia.state.set("feeling", buildState({}, msg))
end

local function readState()
  noctalia.runAsync(bin() .. " export", function(out)
    if out.exitCode ~= 0 then
      publishError(noctalia.tr("no_binary"))
      return
    end
    noctalia.state.set("feeling", buildState(parseCsv(out.stdout), nil))
  end)
end

local function logValue(n)
  n = math.floor(tonumber(n) or 0)
  if n < 1 or n > 10 then return end
  noctalia.runAsync(bin() .. " " .. n .. " -y", function(out)
    if out.exitCode ~= 0 then
      publishError(noctalia.tr("log_failed"))
    else
      readState()
    end
  end)
end

readState()
noctalia.setUpdateInterval(refreshMs())

function update() readState() end

noctalia.state.watch("feeling-log-request", function(req)
  if type(req) ~= "table" then return end
  local at = tonumber(req.at) or 0
  if at <= lastRequestAt then return end   -- debounce duplicate notifications
  lastRequestAt = at
  logValue(req.value)
end)
