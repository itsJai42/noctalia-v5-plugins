import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  property bool vibrantEnabled: false
  property int vibranceValue: 512
  property int displayCount: 1

  onPluginApiChanged: {
    if (pluginApi) {
      loadSettings()
    }
  }

  function loadSettings() {
    var s = pluginApi?.pluginSettings
    var d = pluginApi?.manifest?.metadata?.defaultSettings
    root.vibranceValue  = s?.vibranceValue ?? d?.vibranceValue ?? 512
    root.displayCount   = s?.displayCount  ?? d?.displayCount  ?? 1
    root.vibrantEnabled = s?.enabled       ?? d?.enabled       ?? false
    applyVibrance(root.vibrantEnabled ? root.vibranceValue : 0)
  }

  function buildCmd(value) {
    var parts = ["/usr/sbin/nvibrant"]
    for (var i = 0; i < root.displayCount; i++)
      parts.push(value)
    return parts.join(" ")
  }

  function applyVibrance(value) {
    var cmd = buildCmd(value)
    Logger.i("NVibrant", "Running: " + cmd)
    Qt.createQmlObject(
      'import Quickshell.Io; Process { command: ["bash","-c","' + cmd + '"]; running: true }',
      root, "nvibrantRun"
    )
  }

  function toggle() {
    root.vibrantEnabled = !root.vibrantEnabled
    applyVibrance(root.vibrantEnabled ? root.vibranceValue : 0)
    if (pluginApi) {
      pluginApi.pluginSettings.enabled = root.vibrantEnabled
      pluginApi.saveSettings()
    }
  }

  IpcHandler {
    target: "plugin:nvibrant"
    function toggle() { root.toggle() }
  }
}
