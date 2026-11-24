import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

// Flatbed scan area: preview of the whole glass with a frame that can be
// moved (drag inside), resized (corner handles) or drawn anew (drag outside,
// without zoom). Pinch or double-tap to zoom for small areas.
Page {
    id: page
    allowedOrientations: Orientation.All
    // a horizontal drag in the preview must not swipe back to the main page
    backNavigation: !viewBox.editing

    readonly property real glassW: scanner.glassSize.width > 0 ? scanner.glassSize.width : 215.9
    readonly property real glassH: scanner.glassSize.height > 0 ? scanner.glassSize.height : 297.18
    readonly property int dpi: scanner.resolutions.length > 0 && scanner.dpiIndex >= 0
                               ? scanner.resolutions[scanner.dpiIndex] : 300
    readonly property real maxPixels: 150e6

    // frame being edited, in mm (empty area = whole page)
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    readonly property bool hasSel: selW >= 1 && selH >= 1

    function loadArea() {
        var a = scanner.scanArea
        selX = a.x; selY = a.y; selW = a.width; selH = a.height
    }
    function storeArea() {
        scanner.scanArea = hasSel ? Qt.rect(selX, selY, selW, selH) : Qt.rect(0, 0, 0, 0)
    }
    function clampSel() {
        selW = Math.max(1, Math.min(selW, glassW))
        selH = Math.max(1, Math.min(selH, glassH))
        selX = Math.max(0, Math.min(selX, glassW - selW))
        selY = Math.max(0, Math.min(selY, glassH - selH))
    }
    function fmt(v) { return v < 10 ? v.toFixed(1) : Math.round(v).toString() }

    Component.onCompleted: {
        loadArea()
        // no preview yet: start one right away
        if (scanner.previewImage.length === 0 && scanner.ready && !scanner.busy)
            scanner.preview()
    }
    Connections {
        target: scanner
        onScanAreaChanged: loadArea()
    }

    SpaceBackground { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge
        // the frame and the zoomed preview need the drag gestures
        interactive: !viewBox.editing

        PullDownMenu {
            MenuItem {
                text: qsTr("Whole page")
                enabled: page.hasSel
                onClicked: { page.selW = 0; page.selH = 0; page.storeArea() }
            }
            MenuItem {
                text: scanner.previewing ? qsTr("Cancel") : qsTr("Preview scan")
                enabled: scanner.previewing || (scanner.ready && !scanner.busy)
                onClicked: scanner.previewing ? scanner.cancel() : scanner.preview()
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Scan area")
                description: scanner.status
            }

            Item {
                id: viewBox
                property bool editing: false
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: page.isPortrait ? page.height * 0.58 : page.height * 0.72

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.paddingMedium
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                }

                Flickable {
                    id: zoomer
                    property real zoom: 1.0
                    anchors.fill: parent
                    anchors.margins: Theme.paddingSmall
                    clip: true
                    contentWidth: width * zoom
                    contentHeight: height * zoom
                    interactive: zoom > 1.0 && !viewBox.editing
                    boundsBehavior: Flickable.StopAtBounds

                    function reset() { zoom = 1.0; contentX = 0; contentY = 0 }
                    function zoomAt(z, px, py) {   // px/py: point in the view
                        var cx = (contentX + px) / zoom, cy = (contentY + py) / zoom
                        zoom = z
                        contentX = Math.max(0, Math.min(contentWidth - width, cx * z - px))
                        contentY = Math.max(0, Math.min(contentHeight - height, cy * z - py))
                    }

                    PinchArea {
                        width: zoomer.contentWidth
                        height: zoomer.contentHeight
                        property real startZoom: 1.0
                        onPinchStarted: startZoom = zoomer.zoom
                        onPinchUpdated: zoomer.zoomAt(Math.max(1.0, Math.min(16.0, startZoom * pinch.scale)),
                                                      pinch.center.x - zoomer.contentX,
                                                      pinch.center.y - zoomer.contentY)

                        // the glass, scaled to fit
                        Item {
                            id: sheet
                            readonly property real s: Math.min(parent.width / page.glassW,
                                                               parent.height / page.glassH)   // px per mm
                            width: page.glassW * s
                            height: page.glassH * s
                            anchors.centerIn: parent

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.25)
                            }

                            Image {
                                anchors.fill: parent
                                fillMode: Image.Stretch
                                asynchronous: true
                                cache: false
                                smooth: true
                                source: scanner.previewing && scanner.liveImage.length > 0
                                        ? "" : scanner.previewImage
                                sourceSize.width: 2400
                            }
                            // live preview while scanning: top aligned, grows downwards
                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                verticalAlignment: Image.AlignTop
                                visible: scanner.previewing
                                asynchronous: true
                                cache: false
                                source: scanner.previewing ? scanner.liveImage : ""
                            }

                            Label {
                                anchors.centerIn: parent
                                width: parent.width - 2 * Theme.paddingLarge
                                visible: scanner.previewImage.length === 0 && !scanner.previewing
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                text: qsTr("Tap “Preview” for a preview scan of the glass, "
                                           + "then tap the part to scan or drag a frame around it.")
                            }

                            // background: draw a new frame (not while zoomed: then it pans)
                            MouseArea {
                                anchors.fill: parent
                                property real sx: 0
                                property real sy: 0
                                property bool moved: false
                                preventStealing: zoomer.zoom <= 1.0
                                onPressed: {
                                    sx = mouse.x / sheet.s; sy = mouse.y / sheet.s
                                    moved = false
                                    if (zoomer.zoom <= 1.0)
                                        viewBox.editing = true
                                }
                                onClicked: {
                                    if (moved || page.hasSel)
                                        return
                                    // a tap places a 20 × 20 mm frame there
                                    page.selW = Math.min(20, page.glassW)
                                    page.selH = Math.min(20, page.glassH)
                                    page.selX = sx - page.selW / 2
                                    page.selY = sy - page.selH / 2
                                    page.clampSel()
                                    page.storeArea()
                                }
                                onPositionChanged: {
                                    if (!viewBox.editing)
                                        return
                                    moved = true
                                    var x = Math.max(0, Math.min(page.glassW, mouse.x / sheet.s))
                                    var y = Math.max(0, Math.min(page.glassH, mouse.y / sheet.s))
                                    page.selX = Math.min(sx, x); page.selY = Math.min(sy, y)
                                    page.selW = Math.abs(x - sx); page.selH = Math.abs(y - sy)
                                }
                                onReleased: {
                                    if (viewBox.editing && moved && page.hasSel)
                                        page.storeArea()
                                    else if (viewBox.editing && moved)
                                        page.loadArea()   // too small: keep the old frame
                                    viewBox.editing = false
                                }
                                onCanceled: { viewBox.editing = false; page.loadArea() }
                                onDoubleClicked: {
                                    if (zoomer.zoom > 1.0)
                                        zoomer.reset()
                                    else
                                        zoomer.zoomAt(4.0, mouse.x + sheet.x - zoomer.contentX,
                                                      mouse.y + sheet.y - zoomer.contentY)
                                }
                            }

                            // the frame
                            Rectangle {
                                id: frame
                                visible: page.hasSel
                                x: page.selX * sheet.s
                                y: page.selY * sheet.s
                                width: page.selW * sheet.s
                                height: page.selH * sheet.s
                                color: Qt.rgba(1, 0.54, 0, 0.12)
                                border.width: 2
                                border.color: "#ff8a00"

                                MouseArea {   // move
                                    anchors.fill: parent
                                    preventStealing: true
                                    property real mx: 0
                                    property real my: 0
                                    property real ox: 0
                                    property real oy: 0
                                    onPressed: {
                                        var p = mapToItem(sheet, mouse.x, mouse.y)
                                        mx = p.x; my = p.y; ox = page.selX; oy = page.selY
                                        viewBox.editing = true
                                    }
                                    onPositionChanged: {
                                        var p = mapToItem(sheet, mouse.x, mouse.y)
                                        page.selX = ox + (p.x - mx) / sheet.s
                                        page.selY = oy + (p.y - my) / sheet.s
                                        page.clampSel()
                                    }
                                    onReleased: { viewBox.editing = false; page.storeArea() }
                                    onCanceled: { viewBox.editing = false; page.storeArea() }
                                }
                            }

                            // corner handles: constant size on screen
                            Repeater {
                                model: 4   // 0 top left, 1 top right, 2 bottom left, 3 bottom right
                                Rectangle {
                                    readonly property bool atRight: index === 1 || index === 3
                                    readonly property bool atBottom: index >= 2
                                    readonly property real size: Theme.itemSizeExtraSmall * 0.7
                                    visible: page.hasSel
                                    width: size; height: size; radius: size / 2
                                    x: (atRight ? frame.x + frame.width : frame.x) - size / 2
                                    y: (atBottom ? frame.y + frame.height : frame.y) - size / 2
                                    color: Qt.rgba(1, 0.54, 0, 0.35)
                                    border.width: 2
                                    border.color: "#ff8a00"

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -Theme.paddingMedium
                                        preventStealing: true
                                        onPressed: viewBox.editing = true
                                        onPositionChanged: {
                                            var p = mapToItem(sheet, mouse.x, mouse.y)
                                            var x = Math.max(0, Math.min(page.glassW, p.x / sheet.s))
                                            var y = Math.max(0, Math.min(page.glassH, p.y / sheet.s))
                                            var l = page.selX, t = page.selY
                                            var r = page.selX + page.selW, b = page.selY + page.selH
                                            if (parent.atRight) r = Math.max(l + 1, x); else l = Math.min(r - 1, x)
                                            if (parent.atBottom) b = Math.max(t + 1, y); else t = Math.min(b - 1, y)
                                            page.selX = l; page.selY = t
                                            page.selW = r - l; page.selH = b - t
                                        }
                                        onReleased: { viewBox.editing = false; page.storeArea() }
                                        onCanceled: { viewBox.editing = false; page.storeArea() }
                                    }
                                }
                            }
                        }
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Medium
                    running: scanner.previewing && scanner.liveImage.length === 0
                }

                Label {
                    anchors { top: parent.top; right: parent.right; margins: Theme.paddingMedium }
                    visible: zoomer.zoom > 1.0
                    text: Math.round(zoomer.zoom * 100) + " %"
                    color: "#ff8a00"
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            ComboBox {
                label: qsTr("Resolution")
                enabled: scanner.resolutions.length > 0 && !scanner.busy
                currentIndex: scanner.dpiIndex
                menu: ContextMenu {
                    Repeater {
                        model: scanner.resolutions
                        MenuItem { text: modelData + " dpi" }
                    }
                }
                onCurrentIndexChanged: if (currentIndex >= 0) scanner.dpiIndex = currentIndex
            }

            Label {
                id: info
                readonly property real wMm: page.hasSel ? page.selW : 210
                readonly property real hMm: page.hasSel ? page.selH : 297
                readonly property real wPx: Math.floor(wMm / 25.4 * page.dpi)
                readonly property real hPx: Math.floor(hMm / 25.4 * page.dpi)
                readonly property bool tooLarge: wPx * hPx > page.maxPixels
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: tooLarge ? "#ff4d4d" : Theme.highlightColor
                text: (page.hasSel
                       ? qsTr("%1 × %2 mm at %3, %4 mm from the left and %5 mm from the top")
                         .arg(page.fmt(page.selW)).arg(page.fmt(page.selH))
                         .arg(page.dpi + " dpi").arg(page.fmt(page.selX)).arg(page.fmt(page.selY))
                       : qsTr("Whole page (A4) at %1").arg(page.dpi + " dpi"))
                      + "\n" + qsTr("%1 × %2 pixels, about %3 MB")
                         .arg(wPx).arg(hPx).arg(Math.max(1, Math.round(wPx * hPx * 3 / 1048576)))
                      + (tooLarge ? "\n" + qsTr("Too large for this resolution – choose a smaller "
                                                + "area or a lower resolution.") : "")
            }

            ScanTile {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                enabled: scanner.ready && !scanner.busy && !info.tooLarge
                title: qsTr("Scan")
                subtitle: page.hasSel ? qsTr("%1 × %2 mm at %3").arg(page.fmt(page.selW))
                                        .arg(page.fmt(page.selH)).arg(page.dpi + " dpi")
                                      : qsTr("Whole page at %1").arg(page.dpi + " dpi")
                onClicked: {
                    page.storeArea()
                    scanner.scan()
                    pageStack.pop()   // the scan appears live on the main page
                }
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                ScanTile {
                    width: parent.width / 2
                    height: Theme.itemSizeLarge
                    accent: scanner.previewing ? "#ff4d4d" : "#3ab0ff"
                    enabled: scanner.previewing || (scanner.ready && !scanner.busy)
                    title: scanner.previewing ? qsTr("Cancel") : qsTr("Preview")
                    onClicked: scanner.previewing ? scanner.cancel() : scanner.preview()
                }
                ScanTile {
                    width: parent.width / 2
                    height: Theme.itemSizeLarge
                    accent: "#3ab0ff"
                    enabled: page.hasSel
                    title: qsTr("Whole page")
                    onClicked: { page.selW = 0; page.selH = 0; page.storeArea() }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Tap the preview to place a frame, drag inside it to move it and drag "
                           + "the corners to resize it. Without zoom, dragging outside draws a new "
                           + "frame; zoomed in, it moves the picture. Pinch or double-tap to zoom.")
            }
        }

        VerticalScrollDecorator { }
    }
}
