--!nonstrict
shortcut.setLabel(noctalia.tr("title")); shortcut.setIcon("device-desktop-pause"); shortcut.setEnabled(noctalia.commandExists("niri-screensaver-launch"))
function onClick() noctalia.runAsync(noctalia.getConfig("launch_command")) end
function onRightClick() noctalia.runAsync(noctalia.getConfig("kill_command")) end
