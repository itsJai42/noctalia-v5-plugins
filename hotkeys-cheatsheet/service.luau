--!nonstrict
local stateKey = "hotkeys-cheatsheet"
local commandKey = "hotkeys-cheatsheet-command"
local busy = false
local lastNonce = 0

local function quote(value)
  return "'" .. tostring(value or ""):gsub("'", "'\\''") .. "'"
end

local function python()
  local configured = noctalia.getConfig("python_binary")
  if type(configured) ~= "string" or noctalia.string.trim(configured) == "" then return "python3" end
  return configured
end

local function helper(args)
  return quote(python()) .. " " .. quote((noctalia.pluginDir() or "") .. "/hotkeys.py") .. " " .. args
end

local function publishError(message)
  noctalia.state.set(stateKey, { selected = "", sets = {}, error = message, updated_at = os.time() })
end

local function refresh()
  if busy then return end
  busy = true
  noctalia.runAsync(helper("dump"), function(result)
    busy = false
    if result.exitCode ~= 0 then
      publishError(result.stderr ~= "" and result.stderr or noctalia.tr("helper_failed"))
      return
    end
    local decoded = noctalia.json.decode(result.stdout)
    if type(decoded) ~= "table" then
      publishError(noctalia.tr("parse_failed"))
      return
    end
    noctalia.state.set(stateKey, decoded)
  end)
end

local function runAndRefresh(args)
  noctalia.runAsync(helper(args), function() refresh() end)
end

local function handleCommand(command)
  if type(command) ~= "table" then return end
  local nonce = tonumber(command.nonce) or os.clock()
  if nonce <= lastNonce then return end
  lastNonce = nonce
  local action = tostring(command.action or "")
  if action == "refresh" then refresh()
  elseif action == "toggle" and command.id then runAndRefresh("toggle " .. quote(command.id))
  elseif action == "select" and command.id then runAndRefresh("select " .. quote(command.id))
  elseif action == "remove" and command.id then runAndRefresh("remove " .. quote(command.id))
  elseif action == "pin" and command.id and command.pin then runAndRefresh("pin --set " .. quote(command.id) .. " --pin " .. quote(command.pin))
  elseif action == "add" and command.name and command.path then
    runAndRefresh("add --name " .. quote(command.name) .. " --kind " .. quote(command.kind or "auto") .. " --path " .. quote(command.path))
  end
end

function update() refresh() end
function onIpc(event) if event == "refresh" then refresh() end end

refresh()
noctalia.setUpdateInterval(math.max(5, tonumber(noctalia.getConfig("refresh_seconds")) or 30) * 1000)
noctalia.state.watch(commandKey, handleCommand)
