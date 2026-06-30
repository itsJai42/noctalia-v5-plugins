--!nonstrict
shortcut.setLabel(noctalia.tr("record")); shortcut.setIcon("circle-dot"); shortcut.setEnabled(noctalia.commandExists("obs-cmd"))
function onClick() noctalia.runAsync("obs-cmd recording toggle") end
