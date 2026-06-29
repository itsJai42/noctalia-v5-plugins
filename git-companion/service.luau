--!nonstrict
local busy = false
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
local function refresh()
  if busy then return end
  local repo = noctalia.getConfig("repository")
  if repo == "" then noctalia.state.set("git", { error = noctalia.tr("configure_repo") }); return end
  busy = true
  local command
  if noctalia.getConfig("platform") == "gitlab" then
    command = "printf '%s %s' \"$(glab issue list -R " .. quote(repo) .. " --output json 2>/dev/null | jq length)\" \"$(glab mr list -R " .. quote(repo) .. " --output json 2>/dev/null | jq length)\""
  else
    command = "printf '%s %s' \"$(gh issue list -R " .. quote(repo) .. " --json number --limit 1000 2>/dev/null | jq length)\" \"$(gh pr list -R " .. quote(repo) .. " --json number --limit 1000 2>/dev/null | jq length)\""
  end
  noctalia.runAsync(command, function(result)
    busy = false
    local issues, requests = result.stdout:match("(%d+)%s+(%d+)")
    noctalia.state.set("git", issues and { issues = tonumber(issues), requests = tonumber(requests), repository = repo } or { error = noctalia.tr("fetch_failed") })
  end, 60000)
end
noctalia.setUpdateInterval(noctalia.getConfig("refresh_seconds") * 1000)
function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end
refresh()
