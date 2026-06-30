--!nonstrict
local urls = {}

function onQuery(query)
  local apiKey = launcher.getConfig("api_key")
  if apiKey == "" then
    launcher.setResults(query, {{ id = "", title = noctalia.tr("missing_key"), glyph = "alert-triangle" }})
    return
  end
  if noctalia.string.trim(query) == "" then
    launcher.setResults(query, {})
    return
  end
  local url = "https://api.giphy.com/v1/gifs/search?limit=20&api_key=" .. noctalia.string.urlEncode(apiKey)
    .. "&rating=" .. noctalia.string.urlEncode(launcher.getConfig("rating"))
    .. "&q=" .. noctalia.string.urlEncode(query)
  noctalia.http({ url = url }, function(response)
    local body = response.ok and noctalia.json.decode(response.body) or nil
    local rows = {}
    urls = {}
    for i, gif in ipairs(type(body) == "table" and body.data or {}) do
      local id = tostring(i)
      local images = gif.images or {}
      local original = images.original or {}
      urls[id] = original.url or gif.url
      table.insert(rows, {
        id = id,
        title = gif.title ~= "" and gif.title or noctalia.tr("untitled"),
        subtitle = noctalia.tr("copy_url"),
        glyph = "gif",
        score = 1000 - i,
        query = query,
      })
    end
    launcher.setResults(query, rows)
  end)
end

function onActivate(id)
  local url = urls[id]
  if url then
    noctalia.copyToClipboard(url, "text/plain")
    noctalia.notify(noctalia.tr("title"), noctalia.tr("copied"))
  end
end
