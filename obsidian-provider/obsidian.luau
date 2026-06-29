--!nonstrict
local vaults = {}

local function loadVaults()
  vaults = {}
  local raw = noctalia.readFile(launcher.getConfig("config_path"))
  local data = raw and noctalia.json.decode(raw) or nil
  for _, vault in pairs(type(data) == "table" and data.vaults or {}) do
    if type(vault) == "table" and type(vault.path) == "string" then
      table.insert(vaults, { name = vault.path:match("([^/]+)/*$") or vault.path, path = vault.path })
    end
  end
end

function onQuery(query)
  loadVaults()
  local rows = {}
  local needle = noctalia.string.trim(query):lower()
  for i, vault in ipairs(vaults) do
    local score = needle == "" and 1 or noctalia.fuzzyScore(needle, vault.name)
    if score then table.insert(rows, { id = tostring(i), title = vault.name, subtitle = vault.path, glyph = "brand-obsidian", score = score }) end
  end
  launcher.setResults(query, rows)
end

function onActivate(id)
  local vault = vaults[tonumber(id)]
  if vault then noctalia.runAsync("xdg-open 'obsidian://open?vault=" .. noctalia.string.urlEncode(vault.name) .. "'") end
end
