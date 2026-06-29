--!nonstrict
local busy = false
local function refresh()
  if busy then return end
  busy = true
  local provider = noctalia.getConfig("provider")
  local command = provider == "claude"
    and [[jq -r '[.totalSessions // 0, .totalMessages // 0] | @tsv' ~/.claude/stats-cache.json 2>/dev/null]]
    or [[printf '%s\t%s' "$(find ~/.codex/sessions -type f 2>/dev/null | wc -l)" "$(wc -l < ~/.codex/history.jsonl 2>/dev/null || echo 0)"]]
  noctalia.runAsync(command, function(result)
    busy = false
    local sessions, messages = result.stdout:match("(%d+)%s+(%d+)")
    noctalia.state.set("usage", sessions and { provider = provider, sessions = tonumber(sessions), messages = tonumber(messages) } or { provider = provider, error = noctalia.tr("unavailable") })
  end)
end
noctalia.setUpdateInterval(noctalia.getConfig("refresh_seconds") * 1000)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end
refresh()
