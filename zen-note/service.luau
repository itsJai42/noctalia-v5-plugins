--!nonstrict
local apiUrl = "https://zenquotes.io/api/quotes"
local stateHome = noctalia.getenv("XDG_STATE_HOME") or ((noctalia.getenv("HOME") or "") .. "/.local/state")
local cachePath = stateHome .. "/noctalia/zen-note.json"
local cache = { quotes = {}, next_index = 1, fetched_at = 0, next_at = 0 }
local busy = false
local lastRequestAt = 0

local function intervalSeconds()
  return math.max(15, tonumber(noctalia.getConfig("quote_interval_minutes")) or 60) * 60
end

local function armTimer()
  local remaining = math.max(60, (tonumber(cache.next_at) or 0) - os.time())
  noctalia.setUpdateInterval(remaining * 1000)
end

local function save()
  local encoded = noctalia.json.encode(cache, true)
  if encoded then noctalia.writeFile(cachePath, encoded) end
end

local function publish(errorMessage)
  local current = type(cache.current) == "table" and cache.current or nil
  noctalia.state.set("quote", {
    text = current and current.q or "",
    author = current and current.a or "",
    next_at = tonumber(cache.next_at) or 0,
    error = errorMessage or "",
    loading = busy and current == nil,
  })
end

local function advance()
  if type(cache.quotes) ~= "table" or #cache.quotes == 0 then return false end
  local index = math.max(1, math.min(#cache.quotes, tonumber(cache.next_index) or 1))
  cache.current = cache.quotes[index]
  cache.next_index = index % #cache.quotes + 1
  cache.next_at = os.time() + intervalSeconds()
  save()
  publish(nil)
  armTimer()
  return true
end

local function load()
  local raw = noctalia.readFile(cachePath)
  local decoded = raw and noctalia.json.decode(raw) or nil
  if type(decoded) == "table" then cache = decoded end
  if type(cache.quotes) ~= "table" then cache.quotes = {} end
  cache.next_index = tonumber(cache.next_index) or 1
  cache.fetched_at = tonumber(cache.fetched_at) or 0
  cache.next_at = tonumber(cache.next_at) or 0
end

local function fetchQuotes(replaceCurrent)
  local now = os.time()
  if busy or now - lastRequestAt < 10 then return end
  busy = true
  lastRequestAt = now
  publish(nil)

  noctalia.http({ url = apiUrl, follow_redirects = true }, function(response)
    busy = false
    local decoded = response.ok and noctalia.json.decode(response.body) or nil
    if type(decoded) ~= "table" then
      publish(noctalia.tr("fetch_failed"))
      armTimer()
      return
    end

    local preferred = {}
    local fallback = {}
    local maxLength = math.max(80, tonumber(noctalia.getConfig("max_quote_length")) or 220)
    for _, item in ipairs(decoded) do
      if type(item) == "table" and type(item.q) == "string" and type(item.a) == "string" then
        local quote = { q = noctalia.string.trim(item.q), a = noctalia.string.trim(item.a) }
        if quote.q ~= "" then
          table.insert(fallback, quote)
          if #quote.q <= maxLength then table.insert(preferred, quote) end
        end
      end
    end

    local quotes = #preferred > 0 and preferred or fallback
    if #quotes == 0 then
      publish(noctalia.tr("empty_response"))
      armTimer()
      return
    end

    cache.quotes = quotes
    cache.next_index = 1
    cache.fetched_at = os.time()
    if replaceCurrent or type(cache.current) ~= "table" then
      advance()
    else
      save()
      publish(nil)
      armTimer()
    end
  end)
end

local function refreshNow()
  fetchQuotes(true)
end

load()
if type(cache.current) == "table" then publish(nil) end
if type(cache.current) ~= "table" then
  fetchQuotes(true)
elseif os.time() >= cache.next_at then
  advance()
else
  armTimer()
end
if os.time() - cache.fetched_at >= 3600 then fetchQuotes(false) end

function update()
  advance()
  if os.time() - cache.fetched_at >= 3600 then fetchQuotes(false) end
end

function onIpc(event)
  if event == "refresh" then refreshNow() end
  if event == "next" and not advance() then fetchQuotes(true) end
end

noctalia.state.watch("next-request", function()
  if not advance() then fetchQuotes(true) end
end)
