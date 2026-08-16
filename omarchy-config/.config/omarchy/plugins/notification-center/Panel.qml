import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar bell + recent-notification list, rebuilt for quattro.
//
// Omarchy's own notification bar widget was removed from core in fc4caf3c and
// republished as omacom.notification-center, but that plugin still binds to
// service.pendingModel / service.pastModel, which ab57ad65 deleted when
// history moved to the last ten entries on disk. So this reads the new shape
// instead:
//
//   live      -> service.popupModel, the toasts currently on screen
//   history   -> ~/.local/state/omarchy/notifications/history/*.json
//
// Live rows win the dedupe, because a toast still on screen is also already
// archived, and the live copy is the one the service can still act on.
Panel {
  id: root
  moduleName: "obsy.notification-center"
  ipcTarget: "obsy.notification-center"
  manageIpc: false

  readonly property var service: bar && bar.shell && typeof bar.shell.firstPartyServiceFor === "function"
    ? bar.shell.firstPartyServiceFor("omarchy.notifications")
    : null

  readonly property bool dnd: service ? service.doNotDisturb === true : false
  // Unread == still on screen. Once a toast expires or is dismissed it stops
  // counting, which is the only "unread" the rewritten service still models.
  readonly property int liveCount: service && service.popupModel ? service.popupModel.count : 0
  readonly property int limit: Math.max(1, Number(setting("limit", 10)) || 10)

  readonly property string historyDir: Quickshell.env("HOME") + "/.local/state/omarchy/notifications/history"

  property var rows: []
  readonly property bool hasRows: rows.length > 0

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // 󰂚 bell, 󰂛 bell-off. The bar shows DND state at a glance so silencing is
  // never invisible — that was the old widget's job too.
  readonly property string bellGlyph: dnd ? "󰂛" : "󰂚"

  function refresh() {
    if (historyProc.running) return
    historyProc.running = true
  }

  function rowKey(e) {
    var id = e.originalId !== undefined && e.originalId !== null ? e.originalId : (e.id || 0)
    return String(id) + ":" + String(e.timestamp || 0)
  }

  function normalize(e) {
    return {
      app: String(e.app || ""),
      appIcon: String(e.appIcon || ""),
      summary: String(e.summary || ""),
      body: String(e.body || ""),
      image: String(e.image || ""),
      glyph: String(e.glyph || ""),
      urgency: typeof e.urgency === "number" ? e.urgency : 1,
      originalId: e.originalId !== undefined && e.originalId !== null ? e.originalId : (e.id || 0),
      timestamp: Number(e.timestamp || 0),
      live: e.live === true
    }
  }

  // Live rows first so they claim the dedupe key before the archived copy.
  function buildRows(raw) {
    var out = []
    var seen = ({})

    if (service && service.popupModel) {
      for (var i = 0; i < service.popupModel.count; i++) {
        var live = service.popupModel.get(i)
        // originalId -1 is the "nothing to replay" placeholder the service
        // inserts, not a real notification.
        if (!live || live.originalId < 0) continue
        var lrow = normalize({
          app: live.app, appIcon: live.appIcon, summary: live.summary,
          body: live.body, image: live.image, glyph: live.glyph,
          urgency: live.urgency, originalId: live.originalId,
          timestamp: live.timestamp, live: true
        })
        if (seen[rowKey(lrow)]) continue
        seen[rowKey(lrow)] = true
        out.push(lrow)
      }
    }

    var lines = String(raw || "").split("\n")
    for (var j = 0; j < lines.length; j++) {
      var line = lines[j].trim()
      if (!line) continue
      try {
        var value = JSON.parse(line)
        if (!value || typeof value !== "object") continue
        var row = normalize(value)
        if (seen[rowKey(row)]) continue
        seen[rowKey(row)] = true
        out.push(row)
      } catch (e) {
        // Torn write from a crash mid-save — skip the line, keep the rest.
      }
    }

    out.sort(function(a, b) { return b.timestamp - a.timestamp })
    return out.slice(0, root.limit)
  }

  function iconSource(icon) {
    var value = String(icon || "")
    if (value.length === 0) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, true)
  }

  function relativeTime(ts) {
    if (!ts) return ""
    var secs = Math.max(0, Math.round((Date.now() - ts) / 1000))
    if (secs < 60) return "now"
    var mins = Math.round(secs / 60)
    if (mins < 60) return mins + "m"
    var hours = Math.round(mins / 60)
    if (hours < 24) return hours + "h"
    return Math.round(hours / 24) + "d"
  }

  function toggleDnd() {
    if (service) service.setDoNotDisturb(!root.dnd)
  }

  function clearAll() {
    if (!service) return
    service.clearPopups()
    service.clearHistory()
    rows = []
    // The archive is deleted asynchronously; re-read once it has settled so a
    // failed delete shows up as the row coming back rather than a false empty.
    clearSettleTimer.restart()
  }

  function dismissRow(row) {
    if (!service || !row) return
    if (row.live && typeof service.removePopupsByOriginalId === "function")
      service.removePopupsByOriginalId(row.originalId)
    var next = []
    for (var i = 0; i < rows.length; i++)
      if (rowKey(rows[i]) !== rowKey(row)) next.push(rows[i])
    rows = next
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  // Keep the badge honest while the panel is open: a toast expiring behind it
  // should drop out of the list rather than linger until the next open.
  Connections {
    target: root.service && root.service.popupModel ? root.service.popupModel : null
    enabled: root.opened
    function onCountChanged() { root.refresh() }
  }

  Timer {
    id: clearSettleTimer
    interval: 250
    onTriggered: root.refresh()
  }

  // Same read the service itself uses: concatenate the archived JSON files.
  // `awk 1` tolerates files without a trailing newline, which a torn write can
  // leave behind.
  Process {
    id: historyProc
    running: false
    command: ["bash", "-c", "awk 1 \"$1\"/*.json 2>/dev/null || true", "--", root.historyDir]
    stdout: StdioCollector {
      onStreamFinished: root.rows = root.buildRows(text)
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
    function clear(): string { root.clearAll(); return "ok" }
    function toggleDnd(): string { root.toggleDnd(); return root.dnd ? "on" : "off" }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fontFamily: root.fontFamily
    text: root.liveCount > 0 ? root.bellGlyph + " " + root.liveCount : root.bellGlyph
    active: root.dnd
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.toggleDnd()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    Flickable {
      anchors.fill: parent
      contentWidth: width
      contentHeight: column.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: column
        width: parent.width
        spacing: Style.space(8)

        PanelSectionHeader {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(12)
          Layout.leftMargin: Style.space(16)
          Layout.rightMargin: Style.space(16)
          text: root.dnd ? "Notifications — silenced" : "Notifications"
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.leftMargin: Style.space(16)
          Layout.rightMargin: Style.space(16)
          spacing: Style.space(8)

          PanelActionButton {
            iconText: root.bellGlyph
            tooltipText: root.dnd ? "Allow notifications" : "Silence notifications"
            foreground: root.foreground
            fontFamily: root.fontFamily
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.toggleDnd()
          }

          Item { Layout.fillWidth: true }

          PanelActionButton {
            iconText: "󰅙"
            tooltipText: "Clear notifications"
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: root.hasRows
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.clearAll()
          }
        }

        AppText {
          Layout.fillWidth: true
          Layout.leftMargin: Style.space(16)
          Layout.rightMargin: Style.space(16)
          Layout.topMargin: Style.space(12)
          Layout.bottomMargin: Style.space(16)
          visible: !root.hasRows
          text: "Nothing recent."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        Repeater {
          model: root.hasRows ? root.rows : []

          delegate: BorderSurface {
            id: rowSurface
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.leftMargin: Style.space(12)
            Layout.rightMargin: Style.space(12)
            Layout.bottomMargin: index === root.rows.length - 1 ? Style.space(16) : 0

            implicitHeight: rowContent.implicitHeight + Style.space(20)
            color: Color.notifications.background
            radius: Style.cornerRadius
            borderSpec: Border.surfaceSpec("notifications", "border", Color.notifications.border, 1)

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              // Left and right both dismiss: there is no reliable way to invoke
              // a notification's default action from an archived row, so
              // offering a click that silently does nothing would be worse.
              onClicked: root.dismissRow(rowSurface.modelData)
            }

            RowLayout {
              id: rowContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              spacing: Style.space(10)

              Item {
                Layout.preferredWidth: Style.space(28)
                Layout.preferredHeight: Style.space(28)
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Style.space(2)
                visible: rowGlyph.visible || rowIcon.visible

                Image {
                  id: rowIcon
                  anchors.fill: parent
                  source: root.iconSource(rowSurface.modelData.image !== ""
                    ? rowSurface.modelData.image
                    : rowSurface.modelData.appIcon)
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  smooth: true
                  visible: source !== "" && status !== Image.Error
                }

                AppText {
                  id: rowGlyph
                  anchors.centerIn: parent
                  visible: rowSurface.modelData.glyph !== "" && !rowIcon.visible
                  text: rowSurface.modelData.glyph
                  color: Color.notifications.text
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.icon
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(2)

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.space(6)

                  AppText {
                    Layout.fillWidth: true
                    text: rowSurface.modelData.summary !== ""
                      ? rowSurface.modelData.summary
                      : rowSurface.modelData.app
                    color: Color.notifications.text
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                    maximumLineCount: 1
                  }

                  AppText {
                    text: root.relativeTime(rowSurface.modelData.timestamp)
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                AppText {
                  Layout.fillWidth: true
                  visible: rowSurface.modelData.body !== ""
                  text: rowSurface.modelData.body
                  color: Qt.darker(Color.notifications.text, 1.15)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                  elide: Text.ElideRight
                  maximumLineCount: 2
                }
              }
            }
          }
        }
      }
    }
  }
}
