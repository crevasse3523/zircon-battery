// Bateria myszy Genesis Zircon 660 Pro: ikona, procent i pasek poziomu.
// Dane czyta z pliku stanu demona zircon-battery, więc sam widget nigdy nie odpytuje myszy.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Shapes

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    readonly property string deviceModel: "Zircon 660 Pro"
    readonly property string stateCommand: 'cat "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/zircon-battery.json"'

    property var batt: ({})

    readonly property bool hasValue: batt.percent !== undefined
    readonly property int percent: hasValue ? batt.percent : 0
    readonly property bool charging: hasValue && !!batt.charging
    readonly property bool online: hasValue && !!batt.online

    // zielony od 50%, płynnie do pomarańczowego przy 20%, poniżej czerwony
    readonly property color levelColor: {
        if (!hasValue) return Kirigami.Theme.disabledTextColor
        if (charging || percent >= 50) return Kirigami.Theme.positiveTextColor
        if (percent >= 20) return Kirigami.ColorUtils.linearInterpolation(
            Kirigami.Theme.neutralTextColor, Kirigami.Theme.positiveTextColor, (percent - 20) / 30)
        return Kirigami.Theme.negativeTextColor
    }

    readonly property string statusText: {
        if (batt.dongle === false) return "Brak odbiornika"
        if (!hasValue) return "Brak odczytu"
        if (!online) return "Mysz uśpiona"
        return ""
    }

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation : compactRepresentation

    toolTipMainText: deviceModel
    toolTipSubText: hasValue ? percent + "%" + (charging ? ", ładowanie" : "") : statusText

    Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: [root.stateCommand]
        interval: 60000
        onNewData: function(sourceName, data) {
            if (Number(data["exit code"]) !== 0) {
                root.batt = {}
                return
            }
            try {
                root.batt = JSON.parse(data["stdout"])
            } catch (e) {
                root.batt = {}
            }
        }
    }

    component LevelBar: Rectangle {
        id: bar
        radius: height / 2
        color: Kirigami.ColorUtils.linearInterpolation(
            Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)
        clip: true

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.max(root.hasValue && root.percent > 0 ? bar.height : 0,
                            bar.width * root.percent / 100)
            radius: bar.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.darker(root.levelColor, 1.35) }
                GradientStop { position: 1; color: root.levelColor }
            }
            Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

            // połysk przesuwający się po pasku w trakcie ładowania
            Rectangle {
                id: shine
                visible: root.charging
                width: fill.width * 0.35
                height: parent.height
                radius: bar.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.35) }
                    GradientStop { position: 1; color: "transparent" }
                }
                NumberAnimation on x {
                    running: root.charging
                    loops: Animation.Infinite
                    from: -shine.width
                    to: fill.width
                    duration: 1800
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.iconSizes.medium
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            width: Math.min(parent.width, parent.height) * 0.75
            height: width
            source: "input-mouse"
            opacity: root.online ? 1 : 0.5
        }
        LevelBar {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
            height: Math.max(3, parent.height * 0.14)
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredHeight: Kirigami.Units.gridUnit * 6
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            text: root.deviceModel
            level: 3
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                source: "input-mouse"
                opacity: root.online ? 1 : 0.45
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Kirigami.Units.smallSpacing / 2
                opacity: root.online ? 1 : 0.55

                QQC2.Label {
                    Layout.alignment: Qt.AlignBaseline
                    text: root.hasValue ? root.percent : "—"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.4
                    font.weight: Font.Light
                    color: root.percent < 20 && root.hasValue && !root.charging
                           ? root.levelColor : Kirigami.Theme.textColor
                }
                QQC2.Label {
                    Layout.alignment: Qt.AlignBaseline
                    text: "%"
                    visible: root.hasValue
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            Item { Layout.fillWidth: true }

            // błyskawica rysowana wektorowo (Breeze nie ma samej błyskawicy jako ikony)
            Shape {
                id: bolt
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                visible: root.charging
                antialiasing: true
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Kirigami.Theme.positiveTextColor
                    startX: bolt.width * 10 / 16; startY: 0
                    PathPolyline {
                        readonly property real sx: bolt.width / 16
                        readonly property real sy: bolt.height / 24
                        path: [Qt.point(10 * sx, 0), Qt.point(0, 14 * sy), Qt.point(7 * sx, 14 * sy),
                               Qt.point(5 * sx, 24 * sy), Qt.point(16 * sx, 9 * sy), Qt.point(9 * sx, 9 * sy),
                               Qt.point(10 * sx, 0)]
                    }
                }

                SequentialAnimation on opacity {
                    running: root.charging
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
                }
            }

            QQC2.Label {
                text: root.statusText
                visible: !root.charging && text.length > 0
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }
        }

        LevelBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 0.6)
        }

        Item { Layout.fillHeight: true }
    }
}
