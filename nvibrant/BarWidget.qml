import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property bool vibrantEnabled: false
  property int vibranceValue: 512
  property int displayCount: 1

  onPluginApiChanged: {
    if (pluginApi) {
      var s = pluginApi.pluginSettings
      var d = pluginApi?.manifest?.metadata?.defaultSettings
      vibrantEnabled = s?.enabled       ?? d?.enabled       ?? false
      vibranceValue  = s?.vibranceValue ?? d?.vibranceValue ?? 512
      displayCount   = s?.displayCount  ?? d?.displayCount  ?? 1
    }
  }

  readonly property real contentWidth: Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function buildCmd(value) {
    var parts = ["/usr/sbin/nvibrant"]
    for (var i = 0; i < displayCount; i++)
      parts.push(value)
    return parts.join(" ")
  }

  function runNvibrant(value) {
    var cmd = buildCmd(value)
    Logger.i("NVibrant", "BarWidget running: " + cmd)
    Qt.createQmlObject(
      'import Quickshell.Io; Process { command: ["bash","-c","' + cmd + '"]; running: true }',
      root, "nvibrantRun"
    )
  }

  function toggle() {
    vibrantEnabled = !vibrantEnabled
    runNvibrant(vibrantEnabled ? vibranceValue : 0)
    if (pluginApi) {
      pluginApi.pluginSettings.enabled = vibrantEnabled
      pluginApi.saveSettings()
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: "contrast"
      applyUiScale: false
      color: root.vibrantEnabled
        ? Color.mPrimary
        : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        "label": root.vibrantEnabled ? "Disable Vibrance" : "Enable Vibrance",
        "action": "toggle",
        "icon": root.vibrantEnabled ? "eye-off" : "eye"
      },
      {
        "label": "Settings",
        "action": "widget-settings",
        "icon": "settings"
      }
    ]
    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)
      if (action === "toggle") {
        root.toggle()
      } else if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        root.toggle()
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }
  }
}
