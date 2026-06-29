--!nonstrict
local workspaces = {}

function onQuery(query)
  noctalia.runAsync("niri msg -j workspaces", function(result)
    local decoded = result.exitCode == 0 and noctalia.json.decode(result.stdout) or nil
    workspaces = type(decoded) == "table" and decoded or {}
    local rows = {}
    local needle = noctalia.string.trim(query):lower()
    for _, ws in ipairs(workspaces) do
      local name = (ws.name and ws.name ~= "") and ws.name or tostring(ws.idx or ws.id)
      local haystack = name .. " " .. tostring(ws.output or "") .. " " .. tostring(ws.idx or "")
      if needle == "" or haystack:lower():find(needle, 1, true) then
        table.insert(rows, {
          id = tostring(ws.id),
          title = name .. (ws.is_focused and noctalia.tr("current") or ""),
          subtitle = tostring(ws.output or ""),
          glyph = ws.is_focused and "check" or "chevron-right",
          query = query,
        })
      end
    end
    launcher.setResults(query, rows)
  end)
end

function onActivate(id)
  noctalia.runAsync("niri msg action focus-workspace --id " .. tostring(tonumber(id)))
end
