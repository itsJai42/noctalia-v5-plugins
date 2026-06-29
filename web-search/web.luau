--!nonstrict
local targets = {}
local engines = {
  google = "https://www.google.com/search?q=",
  duckduckgo = "https://duckduckgo.com/?q=",
  bing = "https://www.bing.com/search?q=",
  brave = "https://search.brave.com/search?q=",
}

local function looksLikeUrl(text)
  return not text:find(" ", 1, true) and (
    text:match("^https?://") or text:match("^localhost[:/]?") or
    text:match("^%d+%.%d+%.%d+%.%d+[:/]?") or text:match("^[%w-]+%.[%w.-]+[:/]?")
  )
end

function onQuery(query)
  local text = noctalia.string.trim(query)
  if text == "" then launcher.setResults(query, {}); return end
  targets = {}
  local rows = {}
  if launcher.getConfig("direct_url") and looksLikeUrl(text) then
    local url = text:match("^https?://") and text or ((text:match("^localhost") or text:match("^%d+%.")) and "http://" or "https://") .. text
    targets.url = url
    table.insert(rows, { id = "url", title = noctalia.tr("open_url", { url = url }), glyph = "link", score = 1000 })
  end
  local engine = engines[launcher.getConfig("search_engine")] or engines.google
  targets.search = engine .. noctalia.string.urlEncode(text)
  table.insert(rows, { id = "search", title = noctalia.tr("search", { query = text }), glyph = "world-search", score = 900 })
  launcher.setResults(query, rows)
end

function onActivate(id)
  local url = targets[id]
  if url then noctalia.runAsync("xdg-open '" .. url:gsub("'", "'\\''") .. "'") end
end
