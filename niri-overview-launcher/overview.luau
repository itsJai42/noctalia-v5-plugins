--!nonstrict
shortcut.setLabel(noctalia.tr("label"))
shortcut.setIcon("layout-dashboard")
shortcut.setEnabled(noctalia.commandExists("niri"))

function onClick()
  noctalia.runAsync("niri msg action toggle-overview")
end
