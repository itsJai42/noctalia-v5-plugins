--!nonstrict
local function render(data)
  data = type(data) == "table" and data or {}
  barWidget.setGlyph(data.error and "alert-circle" or "brand-git")
  barWidget.setText(data.error and "--" or tostring(data.issues or 0) .. " / " .. tostring(data.requests or 0))
  barWidget.setTooltip(data.error or (tostring(data.repository or "") .. "\n" .. noctalia.tr("summary", { issues = data.issues or 0, requests = data.requests or 0 })))
end
render(noctalia.state.get("git")); noctalia.state.watch("git", render)
function onClick() noctalia.togglePanel("noctalia/git-companion:git-panel") end
