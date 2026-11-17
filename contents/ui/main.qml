import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Relógio e mídia"
    preferredRepresentation: compactRepresentation
    fullRepresentation: Item { }
    property date now: new Date()
    // "" (fechado) | "clock" | "media"
    property string openCard: ""
    readonly property bool islandOpen: openCard !== ""
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    // hideOnWindowDeactivate fecha o popup no press, antes do click chegar; sem essa guarda o click reabriria o card
    property string closedCard: ""
    property double closedAt: 0
    function toggleCard(name) {
        if (openCard === "" && closedCard === name && Date.now() - closedAt < 300) return
        openCard = openCard === name ? "" : name
    }
    onOpenCardChanged: if (openCard === "clock") { viewYear = now.getFullYear(); viewMonth = now.getMonth() }
    // dia da semana abreviado, sem o ponto que o locale pt_BR pode devolver ("ter." -> "Ter")
    function weekdayShort(d) {
        const n = Qt.locale().dayName(d.getDay(), Locale.ShortFormat).replace(/\./g, "")
        return n.charAt(0).toUpperCase() + n.slice(1)
    }
    property var player: null
    readonly property bool playing: player && player.status === "Playing"
    readonly property string track: player && player.track ? player.track : "Nenhuma mídia tocando"
    readonly property string artist: player && player.artist ? player.artist : ""
    readonly property string mediaScript: decodeURIComponent(Qt.resolvedUrl("../code/media.py").toString().replace(/^file:\/\//, ""))
    readonly property string mediaCommand: "python3 '" + mediaScript.replace(/'/g, "'\\''") + "'"
    function refreshMedia() { if (collector.connectedSources.indexOf(mediaCommand) < 0) collector.connectSource(mediaCommand) }
    function controlMedia(action) { collector.connectSource(mediaCommand + " " + action) }
    Plasma5Support.DataSource {
        id: collector
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source !== root.mediaCommand) { root.refreshMedia(); return }
            try { const info = JSON.parse(data.stdout || "{}"); root.player = info.instance ? info : null }
            catch (e) { root.player = null }
        }
    }
    Timer { id: refreshTimer; interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshMedia() }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.now = new Date() }

    compactRepresentation: Item {
        id: compact
        readonly property bool stacked: height >= 42
        Layout.minimumWidth: root.playing ? 220 : (stacked ? 100 : 150)
        Layout.preferredWidth: root.playing ? 270 : (stacked ? 100 : 150)
        Layout.minimumHeight: 0
        Rectangle {
            anchors.fill: parent; anchors.margins: 2; radius: height / 2
            color: "transparent"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 7
                // area do relogio: abre o calendario
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: !root.playing
                    Layout.preferredWidth: clockCol.implicitWidth
                    ColumnLayout {
                        id: clockCol
                        anchors.centerIn: parent; spacing: 0
                        Text {
                            text: compact.stacked ? Qt.formatTime(root.now, "HH:mm") : Qt.formatTime(root.now, "HH:mm") + "  " + root.weekdayShort(root.now) + " " + Qt.formatDate(root.now, "dd/MM")
                            color: root.Kirigami.Theme.textColor; font.pixelSize: Math.max(9, Math.min(13, compact.height - 4)); font.bold: true; Layout.alignment: Qt.AlignHCenter; maximumLineCount: 1
                        }
                        Text {
                            visible: compact.stacked
                            text: root.weekdayShort(root.now) + " " + Qt.formatDate(root.now, "dd/MM/yyyy")
                            color: root.Kirigami.Theme.textColor; opacity: 0.8; font.pixelSize: Math.max(9, Math.min(10, compact.height * 0.23)); Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleCard("clock") }
                }
                Rectangle { visible: root.playing; width: 1; height: 16; color: root.Kirigami.Theme.textColor; opacity: 0.25 }
                // area da midia: abre o card do player
                Item {
                    visible: root.playing
                    Layout.fillHeight: true; Layout.fillWidth: true
                    RowLayout {
                        anchors.fill: parent; spacing: 7
                        Text { text: "♪"; color: root.Kirigami.Theme.textColor; font.pixelSize: 16 }
                        Text { text: root.track; color: root.Kirigami.Theme.textColor; font.pixelSize: 12; elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleCard("media") }
                }
            }
        }
    }
    PlasmaCore.Dialog {
        id: islandPopup
        color: "transparent"
        visualParent: root
        location: Plasmoid.location
        backgroundHints: PlasmaCore.Dialog.NoBackground
        hideOnWindowDeactivate: true
        visible: root.islandOpen
        onVisibleChanged: if (!visible && root.openCard !== "") { root.closedCard = root.openCard; root.closedAt = Date.now(); root.openCard = "" }
        mainItem: Item {
        id: full
        readonly property int cardHeight: root.openCard === "clock" ? 330 : 178
        width: 350; height: cardHeight
        Layout.minimumWidth: 350; Layout.preferredWidth: 350
        Layout.minimumHeight: cardHeight; Layout.preferredHeight: cardHeight
        property real reveal: 0
        NumberAnimation on reveal { id: revealAnimation; from: 0; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.65; running: false }
        Component.onCompleted: if (root.islandOpen) revealAnimation.restart()
        Connections { target: root; function onOpenCardChanged() { if (root.islandOpen) revealAnimation.restart() } }
        Rectangle {
            id: island
            anchors.fill: parent; anchors.leftMargin: 1; anchors.rightMargin: 1; anchors.topMargin: 9; anchors.bottomMargin: 1; radius: 28; color: Qt.tint("#111214", Qt.rgba(root.Kirigami.Theme.highlightColor.r, root.Kirigami.Theme.highlightColor.g, root.Kirigami.Theme.highlightColor.b, 0.12)); border.width: 1; border.color: Qt.rgba(root.Kirigami.Theme.highlightColor.r, root.Kirigami.Theme.highlightColor.g, root.Kirigami.Theme.highlightColor.b, 0.5)
            opacity: Math.min(1, Math.max(0, full.reveal * 2))
            scale: 0.86 + 0.14 * full.reveal
            transformOrigin: Item.Top
            ColumnLayout {
                visible: root.openCard === "media"
                anchors.fill: parent; anchors.margins: 18; spacing: 9
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 64; Layout.preferredHeight: 64; radius: 15; color: "#30312d"
                        Rectangle { id: artMask; anchors.fill: parent; radius: 15; visible: false }
                        Image { anchors.fill: parent; source: root.player && root.player.artUrl ? root.player.artUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; layer.enabled: true; layer.effect: OpacityMask { maskSource: artMask } }
                        Text { anchors.centerIn: parent; visible: !root.player || !root.player.artUrl; text: "♫"; color: "#b9bac0"; font.pixelSize: 26 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: root.track; color: "#fafafa"; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: root.artist || (root.player ? "Player de mídia" : "Abra um player para começar"); color: "#a9aab1"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    ColumnLayout {
                        spacing: 5; Layout.alignment: Qt.AlignTop
                        Text { text: Qt.formatTime(root.now, "HH:mm"); color: "#efeee9"; font.pixelSize: 14; font.bold: true; Layout.alignment: Qt.AlignRight }
                        Text { text: root.playing ? "●  TOCANDO" : "●  PAUSADO"; color: root.playing ? root.Kirigami.Theme.highlightColor : "#858581"; font.pixelSize: 9; font.bold: true; Layout.alignment: Qt.AlignRight }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#34342f" }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 24
                    Repeater {
                        model: ["previous", "play", "next"]
                        delegate: Controls.Button {
                            required property var modelData
                            text: modelData === "previous" ? "⏮" : modelData === "next" ? "⏭" : (root.playing ? "❚❚" : "▶")
                            enabled: !!root.player
                            implicitWidth: modelData === "play" ? 44 : 38; implicitHeight: 40
                            contentItem: Text { text: parent.text; color: parent.enabled ? "#f6f6f8" : "#606167"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 19 }
                            background: Rectangle { radius: 20; color: parent.down ? "#53545a" : parent.hovered ? "#38393e" : modelData === "play" ? Qt.tint("#333038", Qt.rgba(root.Kirigami.Theme.highlightColor.r, root.Kirigami.Theme.highlightColor.g, root.Kirigami.Theme.highlightColor.b, 0.18)) : "transparent" }
                            onClicked: root.controlMedia(modelData === "play" ? "play-pause" : modelData)
                        }
                    }
                }
            }
            ColumnLayout {
                visible: root.openCard === "clock"
                anchors.fill: parent; anchors.margins: 18; spacing: 8
                readonly property var firstDay: new Date(root.viewYear, root.viewMonth, 1)
                readonly property int offset: (firstDay.getDay() - Qt.locale().firstDayOfWeek + 7) % 7
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
                        color: "#fafafa"; font.pixelSize: 15; font.bold: true
                        Component.onCompleted: font.capitalization = Font.Capitalize
                    }
                    Repeater {
                        model: [-1, 1]
                        delegate: Controls.Button {
                            required property int modelData
                            implicitWidth: 30; implicitHeight: 30
                            contentItem: Text { text: parent.modelData < 0 ? "‹" : "›"; color: "#f6f6f8"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 20 }
                            background: Rectangle { radius: 15; color: parent.down ? "#53545a" : parent.hovered ? "#38393e" : "transparent" }
                            onClicked: { const d = new Date(root.viewYear, root.viewMonth + modelData, 1); root.viewYear = d.getFullYear(); root.viewMonth = d.getMonth() }
                        }
                    }
                }
                GridLayout {
                    columns: 7; columnSpacing: 0; rowSpacing: 2
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Repeater {
                        model: 7
                        delegate: Text {
                            required property int index
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat).replace(/\./g, "").slice(0, 3)
                            color: "#858581"; font.pixelSize: 11; font.bold: true
                        }
                    }
                    Repeater {
                        model: 42
                        delegate: Item {
                            id: cell
                            required property int index
                            readonly property date day: new Date(root.viewYear, root.viewMonth, 1 - parent.parent.offset + index)
                            readonly property bool inMonth: day.getMonth() === root.viewMonth
                            readonly property bool isToday: day.toDateString() === root.now.toDateString()
                            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                            Rectangle {
                                anchors.centerIn: parent; width: Math.min(parent.width, parent.height); height: width; radius: width / 2
                                color: cell.isToday ? root.Kirigami.Theme.highlightColor : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent; text: cell.day.getDate()
                                color: cell.isToday ? "#ffffff" : cell.inMonth ? "#efeee9" : "#55565b"
                                font.pixelSize: 12; font.bold: cell.isToday
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
