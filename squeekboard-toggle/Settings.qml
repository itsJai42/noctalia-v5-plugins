import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property bool editHideWhenUnavailable: cfg.hideWhenUnavailable ?? defaults.hideWhenUnavailable ?? false
    property bool editDisableHoverIcon: cfg.disableHoverIcon ?? defaults.disableHoverIcon ?? false

    spacing: Style.marginL

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hideWhenUnavailable.label")
        description: pluginApi?.tr("settings.hideWhenUnavailable.desc")
        checked: root.editHideWhenUnavailable
        onToggled: checked => {
            root.editHideWhenUnavailable = checked
            root.saveSettings()
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.disableHoverIcon.label")
        description: pluginApi?.tr("settings.disableHoverIcon.desc")
        checked: root.editDisableHoverIcon
        onToggled: checked => {
            root.editDisableHoverIcon = checked
            root.saveSettings()
        }
    }

    RowLayout {
        Layout.fillWidth: true

        NLabel {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.recheck.desc")
        }

        NButton {
            text: recheckDone ? pluginApi?.tr("settings.recheck.done") : pluginApi?.tr("settings.recheck.label")
            property bool recheckDone: false
            onClicked: {
                pluginApi?.mainInstance?.recheckState()
                recheckDone = true
                recheckTimer.restart()
            }
            Timer {
                id: recheckTimer
                interval: 1500
                onTriggered: parent.recheckDone = false
            }
        }
    }

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.hideWhenUnavailable = root.editHideWhenUnavailable
        pluginApi.pluginSettings.disableHoverIcon = root.editDisableHoverIcon
        pluginApi.saveSettings()
    }
}
