--!nonstrict
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
local function mark(appId, unset)
  if not appId or appId == "" then return end
  noctalia.runAsync("niri msg -j windows", function(result)
    local windows = result.exitCode == 0 and noctalia.json.decode(result.stdout) or nil
    for _, window in ipairs(type(windows) == "table" and windows or {}) do
      local candidate = tostring(window.app_id or ""):lower()
      local needle = tostring(appId):lower()
      if candidate ~= "" and (candidate == needle or candidate:find(needle, 1, true) or needle:find(candidate, 1, true)) then
        noctalia.runAsync("niri msg action " .. (unset and "unset-window-urgent" or "set-window-urgent") .. " --id " .. tostring(window.id))
      end
    end
  end)
end
function onIpc(event, payload) if event == "urgent" then mark(payload, false) elseif event == "clear" then mark(payload, true) end end
noctalia.log(noctalia.tr("automatic_unavailable"))
