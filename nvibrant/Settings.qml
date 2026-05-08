import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property int editVibranceValue: 512
  property int editDisplayCount: 1

  spacing: Style.marginM

  onPluginApiChanged: { if (pluginApi) loadSettings() }
  Component.onCompleted: { if (pluginApi) loadSettings() }

  function loadSettings() {
    var s = pluginApi?.pluginSettings
    var d = pluginApi?.manifest?.metadata?.defaultSettings
    root.editVibranceValue = s?.vibranceValue ?? d?.vibranceValue ?? 512
    root.editDisplayCount  = s?.displayCount  ?? d?.displayCount  ?? 1
    vibranceSpinBox.value   = root.editVibranceValue
    displayCountSpinBox.value = root.editDisplayCount
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Vibrance Level"
      description: "Digital vibrance intensity (0 = default, 1023 = maximum saturation)"
    }

    NSpinBox {
      id: vibranceSpinBox
      from: 0
      to: 1023
      stepSize: 64
      value: root.editVibranceValue
      onValueChanged: if (value !== root.editVibranceValue) root.editVibranceValue = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Display Count"
      description: "Number of displays/ports to apply vibrance to (check nvibrant output)"
    }

    NSpinBox {
      id: displayCountSpinBox
      from: 1
      to: 8
      stepSize: 1
      value: root.editDisplayCount
      onValueChanged: if (value !== root.editDisplayCount) root.editDisplayCount = value
    }
  }

  function saveSettings() {
    if (!pluginApi) return
    pluginApi.pluginSettings.vibranceValue = root.editVibranceValue
    pluginApi.pluginSettings.displayCount  = root.editDisplayCount
    pluginApi.saveSettings()

    var m = pluginApi.mainInstance
    if (m) {
      m.vibranceValue = root.editVibranceValue
      m.displayCount  = root.editDisplayCount
      if (m.vibrantEnabled)
        m.applyVibrance(root.editVibranceValue)
    }
  }
}
