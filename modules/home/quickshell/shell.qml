//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma IconTheme Tela-circle-dracula

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import "utils" as Utils

Scope {
    // Catppuccin Frappé
    readonly property color clBase:     "#303446"
    readonly property color clSurface0: "#414559"
    readonly property color clSurface1: "#51576d"
    readonly property color clOverlay0: "#737994"
    readonly property color clSubtext0: "#a5adce"
    readonly property color clText:     "#c6d0f5"
    readonly property color clBlue:     "#8caaee"

    FloatingWindow {
        id: root
        title: "qs-launcher"
        visible: true
        width: 560
        height: 420
        color: "transparent"

        property var currentApps: []

        Component.onCompleted: {
            currentApps = Utils.AppSearch.fuzzyQuery("");
            searchInput.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: clBase
            radius: 12
            border.color: clSurface1
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Search input
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    color: clSurface0
                    radius: 8
                    border.color: searchInput.activeFocus ? clBlue : clOverlay0
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "RecMonoCasual Nerd Font"
                            font.pixelSize: 16
                            color: clSubtext0
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search apps..."
                            placeholderTextColor: clSubtext0
                            color: clText
                            font.family: "RecMonoCasual Nerd Font"
                            font.pixelSize: 15
                            background: null
                            focus: true

                            Keys.onEscapePressed: Qt.quit()
                            Keys.onDownPressed: appList.incrementCurrentIndex()
                            Keys.onUpPressed: appList.decrementCurrentIndex()
                            onAccepted: {
                                var target = appList.currentIndex >= 0
                                    ? root.currentApps[appList.currentIndex]
                                    : root.currentApps[0];
                                if (target) {
                                    Utils.AppSearch.logLaunch(target.name);
                                    target.execute();
                                    Qt.quit();
                                }
                            }
                            onTextChanged: {
                                root.currentApps = Utils.AppSearch.fuzzyQuery(text);
                                appList.currentIndex = -1;
                            }
                        }
                    }
                }

                // Results
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.currentApps
                    spacing: 4
                    clip: true
                    currentIndex: -1
                    highlight: Rectangle {
                        color: clBlue
                        opacity: 0.15
                        radius: 8
                    }
                    highlightMoveDuration: 80

                    delegate: Rectangle {
                        width: appList.width
                        height: 48
                        color: delegateMouse.containsMouse ? clSurface1 : clSurface0
                        radius: 8
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Image {
                                source: Utils.AppSearch.getIcon(modelData.icon)
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                asynchronous: true
                                antialiasing: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: clText
                                font.family: "RecMonoCasual Nerd Font"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Utils.AppSearch.logLaunch(modelData.name);
                                modelData.execute();
                                Qt.quit();
                            }
                        }
                    }
                }
            }
        }
    }
}
