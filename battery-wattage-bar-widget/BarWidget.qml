import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen?.name || ""
    readonly property bool isVertical: ["left", "right"].includes(Settings.getBarPositionForScreen(screenName))
    readonly property string fixedFont: Settings.data?.ui?.fontFixed || "0xProto Nerd Font Mono"

    property string displayText: "0% 0.0W"
    property real wattNum: 0.0
    property int batPercent: 0
    property string batStatus: "Unknown"
    property string batIcon: "battery-4"
    property string timeRemaining: "Calculating..."

    function getBatteryIcon(percentage, status) {
        if (status === "Charging") return "battery-charging";
        if (percentage >= 90) return "battery-4";
        if (percentage >= 65) return "battery-3";
        if (percentage >= 35) return "battery-2";
        if (percentage >= 10) return "battery-1";
        return "battery-off";
    }

    Scope {
        Process {
            id: batProc
            command: ["sh", "-c", "
                UP_OUT=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0)
                echo \"$(echo \"$UP_OUT\" | grep percentage | awk '{print $2}' | tr -d '%')\"
                echo \"$(echo \"$UP_OUT\" | grep energy-rate | awk '{print $2}')\"
                echo \"$(echo \"$UP_OUT\" | grep state | awk '{print $2}')\"
                echo \"$(echo \"$UP_OUT\" | grep -E 'time to (empty|full)' | awk '{print $4 \" \" $5}')\"
            "]
            stdout: StdioCollector {
                onTextChanged: {
                    let lines = text.trim().split("\n");
                    if (lines.length >= 4) {
                        root.batPercent = parseInt(lines[0]);
                        root.wattNum = parseFloat(lines[1].replace(',', '.')) || 0.0;
                        let s = lines[2].trim();
                        root.batStatus = s.charAt(0).toUpperCase() + s.slice(1);
                        
                        let rawTime = lines[3].trim();
                        if (!rawTime || rawTime === "") {
                            root.timeRemaining = "Calculating...";
                        } else {
                            let parts = rawTime.split(" ");
                            let val = parseFloat(parts[0].replace(',', '.'));
                            let unit = parts[1];

                            if (unit && unit.includes("hour")) {
                                let h = Math.floor(val);
                                let m = Math.round((val - h) * 60);
                                root.timeRemaining = h + "h " + m + "m";
                            } else if (unit) {
                                root.timeRemaining = Math.round(val) + "m";
                            } else {
                                root.timeRemaining = "Calculating...";
                            }
                        }
                        
                        let sign = (root.batStatus === "Charging") ? "+" : (root.batStatus === "Discharging" ? "-" : "");
                        root.displayText = root.batPercent + "% " + sign + root.wattNum.toFixed(1) + "W";
                        root.batIcon = getBatteryIcon(root.batPercent, root.batStatus);
                    }
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: batProc.running = true
        }
    }

    // L'Item radice occupa tutta l'altezza della barra
    implicitWidth: layout.implicitWidth + (Style.marginL * 1)
    implicitHeight: Style.barHeight

    Rectangle {
        id: capsule
        // Centriamo la pillola per lasciare spazio sopra e sotto
        anchors.centerIn: parent
        
        // Ridurre l'altezza rispetto alla barra per creare il padding verticale
        height: Style.barHeight - (Style.marginS * 1)
        width: parent.width
        
        radius: Style.radiusM

        color: (root.batStatus === "Charging") ? Color.alpha(Color.mPrimary, Style.capsuleColor.a || 0.4) : Style.capsuleColor
        
        border {
            color: (root.batStatus === "Charging") ? Color.mPrimary : Style.capsuleBorderColor
            width: Style.capsuleBorderWidth
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                let labelTime = root.batStatus === "Charging" ? "Until full" : "Remaining";
                let tooltipText = "<table style='width: 170px;'>" +
                    "<tr><td align='left'>Battery level</td><td align='right'><b>" + root.batPercent + "%</b></td></tr>" +
                    "<tr><td align='left'>Status</td><td align='right'><b>" + root.batStatus + "</b></td></tr>" +
                    "<tr><td align='left'>" + labelTime + "</td><td align='right' style='color:" + Color.mPrimary + ";'><b>" + root.timeRemaining + "</b></td></tr>" +
                    "</table>";
                
                TooltipService.show(root, tooltipText, BarService.getTooltipDirection())
            }

            onExited: TooltipService.hide()
        }

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                Layout.alignment: Qt.AlignCenter
                icon: root.batIcon
                color: (root.batStatus === "Charging") ? Color.mPrimary : (root.batStatus === "Discharging" && root.wattNum > 22.0 ? "#ff5555" : Color.resolveColorKey("none"))
            }

            Text {
                text: root.displayText
                font.pointSize: Style.getBarFontSizeForScreen(screenName)
                font.family: root.fixedFont
                font.bold: true
                color: (root.batStatus === "Charging") ? Color.mPrimary : (root.batStatus === "Discharging" && root.wattNum > 22.0 ? "#ff5555" : Color.mOnSurface)
                Layout.alignment: Qt.AlignCenter
                font.features: ({ "tnum": 1 })
            }
        }
    }
}