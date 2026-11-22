
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets

ShellRoot {
    id: shell

    readonly property string wallpapersDir: Quickshell.env("HOME") + "/wallDir"
    readonly property bool isRu: Quickshell.env("LANG").startsWith("ru")

    readonly property var tr: isRu ? ({
        searchPlaceholder: "Поиск обоев... (нажми /)",
        hint: "← / → или колесо — листать   •   Enter / клик — применить   •   / — поиск   •   Esc — выход",
        empty: "Обои не найдены в "
    }) : ({
        searchPlaceholder: "Search wallpapers... (press /)",
        hint: "← / → or scroll — browse   •   Enter / click — apply   •   / — search   •   Esc — exit",
        empty: "No wallpapers found in "
    })

    Process {
        id: initDirProc
        command: ["mkdir", "-p", shell.wallpapersDir]
        onExited: {
            wallModel.folder = "";
            wallModel.folder = "file://" + shell.wallpapersDir;
        }
    }

    Component.onCompleted: {
        initDirProc.running = true;
    }

    IpcHandler {
        target: "wallpicker"
        function toggle(): void {
            pickerWindow.visible = !pickerWindow.visible;
        }
    }

    PanelWindow {
        id: pickerWindow
        visible: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: pickerWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "wallpaper-picker"

        onVisibleChanged: {
            if (visible) {
                backdrop.forceActiveFocus();
            }
        }

        Process {
            id: applyProc
            onExited: pickerWindow.visible = false
        }

        function applyWallpaper(fileUrl) {
            if (!fileUrl) return;
            const safeUrl = fileUrl.toString().replace(/'/g, "\\'");
            const script = "var allDesktops = desktops(); for (var i = 0; i < allDesktops.length; i++) { var d = allDesktops[i]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); d.writeConfig('Image', '" + safeUrl + "'); }";
            applyProc.command = [
                "qdbus6",
                "org.kde.plasmashell",
                "/PlasmaShell",
                "org.kde.PlasmaShell.evaluateScript",
                script
            ];
            applyProc.running = true;
        }

        FolderListModel {
            id: wallModel
            folder: "file://" + shell.wallpapersDir
            showDirs: false
            sortField: FolderListModel.Name
            nameFilters: {
                const q = searchInput.text.trim();
                if (q === "") {
                    return ["*.jpg", "*.jpeg", "*.png", "*.webp"];
                }
                return [
                    "*" + q + "*.jpg",
                    "*" + q + "*.jpeg",
                    "*" + q + "*.png",
                    "*" + q + "*.webp"
                ];
            }
        }

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "#aa0c0d10"
            focus: true

            MouseArea {
                anchors.fill: parent
                onClicked: pickerWindow.visible = false
            }

            Keys.onEscapePressed: pickerWindow.visible = false
            Keys.onLeftPressed: carousel.decrementCurrentIndex()
            Keys.onRightPressed: carousel.incrementCurrentIndex()
            Keys.onReturnPressed: {
                if (wallModel.count > 0) {
                    pickerWindow.applyWallpaper(wallModel.get(carousel.currentIndex, "fileUrl"));
                }
            }
            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Slash) {
                    searchInput.forceActiveFocus();
                    event.accepted = true;
                }
            }

            Rectangle {
                id: searchBar
                width: 380
                height: 44
                radius: 22
                color: "#e61b1d24"
                border.color: searchInput.activeFocus ? "#88ffffff" : "#33ffffff"
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: carousel.top
                anchors.bottomMargin: 36
                z: 20

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#ffffff"
                    font.pixelSize: 15
                    clip: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        text: shell.tr.searchPlaceholder
                        color: "#77ffffff"
                        font.pixelSize: 15
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onEscapePressed: {
                        if (text !== "") {
                            text = "";
                        } else {
                            backdrop.forceActiveFocus();
                        }
                    }
                    Keys.onReturnPressed: {
                        if (wallModel.count > 0) {
                            pickerWindow.applyWallpaper(wallModel.get(carousel.currentIndex, "fileUrl"));
                        }
                    }
                    Keys.onDownPressed: backdrop.forceActiveFocus()
                }
            }

            PathView {
                id: carousel
                width: Math.min(parent.width * 0.85, 1300)
                height: 440
                anchors.centerIn: parent
                model: wallModel
                pathItemCount: 5
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 260
                interactive: true

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y > 0) carousel.decrementCurrentIndex();
                        else if (event.angleDelta.y < 0) carousel.incrementCurrentIndex();
                    }
                }

                path: Path {
                    startX: 80
                    startY: carousel.height / 2
                    PathAttribute { name: "cardScale"; value: 0.58 }
                    PathAttribute { name: "cardOpacity"; value: 0.45 }
                    PathAttribute { name: "cardZ"; value: 1 }

                    PathLine { x: carousel.width * 0.25; y: carousel.height / 2 }
                    PathAttribute { name: "cardScale"; value: 0.78 }
                    PathAttribute { name: "cardOpacity"; value: 0.80 }
                    PathAttribute { name: "cardZ"; value: 5 }

                    PathLine { x: carousel.width * 0.5; y: carousel.height / 2 }
                    PathAttribute { name: "cardScale"; value: 1.0 }
                    PathAttribute { name: "cardOpacity"; value: 1.0 }
                    PathAttribute { name: "cardZ"; value: 10 }
                    PathLine { x: carousel.width * 0.75; y: carousel.height / 2 }
                    PathAttribute { name: "cardScale"; value: 0.78 }
                    PathAttribute { name: "cardOpacity"; value: 0.80 }
                    PathAttribute { name: "cardZ"; value: 5 }

                    PathLine { x: carousel.width - 80; y: carousel.height / 2 }
                    PathAttribute { name: "cardScale"; value: 0.58 }
                    PathAttribute { name: "cardOpacity"; value: 0.45 }
                    PathAttribute { name: "cardZ"; value: 1 }
                }

                delegate: Item {
                    id: cardRoot
                    required property url fileUrl
                    required property string fileName
                    required property int index

                    width: 640
                    height: 360
                    scale: PathView.cardScale ?? 1.0
                    opacity: PathView.cardOpacity ?? 1.0
                    z: PathView.cardZ ?? 1

                    readonly property bool isCurrent: PathView.isCurrentItem

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 20
                        color: "#18181b"
                        border.width: cardRoot.isCurrent ? 2 : 0
                        border.color: "#ccffffff"

                        Image {
                            anchors.fill: parent
                            source: cardRoot.fileUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize: Qt.size(960, 540)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 44
                            color: "#99000000"
                            visible: cardRoot.isCurrent

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 24
                                text: cardRoot.fileName
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (cardRoot.isCurrent) {
                                pickerWindow.applyWallpaper(cardRoot.fileUrl);
                            } else {
                                carousel.currentIndex = cardRoot.index;
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: carousel.bottom
                anchors.topMargin: 28
                z: 20
                text: wallModel.count > 0 ? shell.tr.hint : shell.tr.empty + shell.wallpapersDir
                color: "#99ffffff"
                font.pixelSize: 13
            }
        }
    }
}
