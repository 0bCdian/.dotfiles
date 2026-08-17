import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar bell + searchable notification list, rebuilt for quattro.
//
// Omarchy's own notification bar widget was removed from core in fc4caf3c and
// republished as omacom.notification-center, but that plugin still binds to
// service.pendingModel / service.pastModel, which ab57ad65 deleted when
// history moved to the last ten entries on disk. So this reads the new shape:
//
//   live      -> service.popupModel, the toasts currently on screen
//   history   -> service.historyDir, one JSON file per archived notification
//
// Search, the hidden-key dismissal trick, and the polled refresh are lifted
// from Shavanced/omarchy-notification-center-plugin (MIT), which solves the
// same problem against the same API.
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

  // Ask the service where history lives rather than hardcoding the path, so a
  // future upstream move follows automatically.
  readonly property string historyDir: service && service.historyDir
    ? String(service.historyDir)
    : Quickshell.env("HOME") + "/.local/state/omarchy/notifications/history"
  readonly property int historyLimit: service && service.historyLimit
    ? Number(service.historyLimit)
    : Math.max(1, Number(setting("limit", 10)) || 10)

  property string query: ""
  property var rows: []
  // The service exposes no per-entry history removal, so a dismissed archive
  // row is remembered here instead. Without this the row returns on the next
  // refresh, because refresh re-reads the files the row still lives in.
  property var hiddenKeys: ({})

  readonly property bool hasRows: rows.length > 0
  readonly property bool searching: query.trim() !== ""

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // 󰂚 bell, 󰂛 bell-off. The bar shows DND state at a glance so silencing is
  // never invisible.
  readonly property string bellGlyph: dnd ? "󰂛" : "󰂚"

  function refresh() {
    if (historyProc.running) return
    historyProc.command = ["bash", "-c",
      "awk 1 \"$1\"/*.json 2>/dev/null || true", "--", root.historyDir]
    historyProc.running = true
  }

  function rowKey(e) {
    var id = e.originalId !== undefined && e.originalId !== null ? e.originalId : (e.id || 0)
    return String(id) + ":" + String(e.timestamp || 0)
  }

  // Strip the inline <img> markup senders embed, and for Chromium-derived
  // apps the leading origin they prepend to every body.
  function sanitizeBody(body, app, appIcon) {
    var text = String(body || "").replace(/<img[^>]*>/gi, "")
    var id = (String(app || "") + " " + String(appIcon || "")).toLowerCase()
    var chromium = id.indexOf("chrom") >= 0 || id.indexOf("brave") >= 0 || id.indexOf("edge") >= 0
    if (!chromium) return text
    return text
      .replace(/^\s*<a\b[^>]*>\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/[^<\s]*)?\s*<\/a>\s*/i, "")
      .replace(/^\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/\S*)?\s+/i, "")
  }

  function matches(row) {
    var needle = root.query.trim().toLowerCase()
    if (needle === "") return true
    return [row.app, row.summary, row.body].join(" ").toLowerCase().indexOf(needle) >= 0
  }

  function normalize(e, live) {
    var app = String(e.app || e.appName || "")
    return {
      app: app,
      appIcon: String(e.appIcon || ""),
      summary: String(e.summary || ""),
      body: sanitizeBody(e.body, app, e.appIcon),
      image: String(e.image || ""),
      glyph: String(e.glyph || ""),
      urgency: typeof e.urgency === "number" ? e.urgency : 1,
      originalId: e.originalId !== undefined && e.originalId !== null ? e.originalId : (e.id || 0),
      timestamp: Number(e.timestamp || 0),
      live: live === true,
      index: e.index !== undefined ? e.index : -1
    }
  }

  // Live rows first so they claim the dedupe key before the archived copy.
  function rebuild(raw) {
    var out = []
    var seen = ({})

    if (service && service.popupModel) {
      for (var i = 0; i < service.popupModel.count; i++) {
        var live = service.popupModel.get(i)
        // originalId -1 is the "nothing to replay" placeholder the service
        // inserts, not a real notification.
        if (!live || live.originalId < 0) continue
        var lrow = normalize({
          app: live.app, appName: live.appName, appIcon: live.appIcon,
          summary: live.summary, body: live.body, image: live.image,
          glyph: live.glyph, urgency: live.urgency,
          originalId: live.originalId, timestamp: live.timestamp, index: i
        }, true)
        var lkey = rowKey(lrow)
        if (seen[lkey] || !matches(lrow)) { seen[lkey] = true; continue }
        seen[lkey] = true
        out.push(lrow)
      }
    }

    var lines = String(raw === undefined ? root.lastRaw : raw || "").split("\n")
    for (var j = 0; j < lines.length; j++) {
      var line = lines[j].trim()
      if (!line) continue
      try {
        var value = JSON.parse(line)
        if (!value || typeof value !== "object") continue
        var row = normalize(value, false)
        var key = rowKey(row)
        if (seen[key] || root.hiddenKeys[key]) continue
        seen[key] = true
        if (!matches(row)) continue
        out.push(row)
      } catch (e) {
        // Torn write from a crash mid-save — skip the line, keep the rest.
      }
    }

    out.sort(function(a, b) { return b.timestamp - a.timestamp })
    rows = out.slice(0, root.historyLimit + (service && service.popupModel ? service.popupModel.count : 0))
  }

  // Kept so a query change can re-filter without re-reading the files.
  property string lastRaw: ""

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
    hiddenKeys = ({})
    lastRaw = ""
    rows = []
    clearSettleTimer.restart()
  }

  function dismissRow(row) {
    if (!service || !row) return
    if (row.live) {
      if (typeof service.removePopupsByOriginalId === "function")
        service.removePopupsByOriginalId(row.originalId)
      else if (row.index >= 0 && typeof service.dismissPopup === "function")
        service.dismissPopup(row.index)
    } else {
      var next = Object.assign({}, root.hiddenKeys)
      next[rowKey(row)] = true
      hiddenKeys = next
    }
    rebuild()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    query = ""
    refresh()
    Qt.callLater(function() { if (root.opened) searchField.forceActiveFocus() })
  }

  onQueryChanged: rebuild()

  // popupModel emits more than countChanged: an in-place update (a sender
  // replacing its own notification) only moves a role, so listen for those too.
  Connections {
    target: root.service && root.service.popupModel ? root.service.popupModel : null
    enabled: root.opened
    function onCountChanged() { root.rebuild() }
    function onDataChanged() { root.rebuild() }
    function onRowsInserted() { root.rebuild() }
    function onRowsRemoved() { root.rebuild() }
    function onModelReset() { root.rebuild() }
  }

  // The archive is written by a detached process, so there is no signal to
  // watch — poll while the panel is open and stop the moment it closes.
  Timer {
    interval: 500
    repeat: true
    running: root.opened
    onTriggered: root.refresh()
  }

  Timer {
    id: clearSettleTimer
    interval: 250
    onTriggered: root.refresh()
  }

  Process {
    id: historyProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root.lastRaw = text; root.rebuild(text) }
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
    // Also the only way to exercise the filter without a keyboard: a
    // layer-shell panel holds a focus grab, so synthesised keys go to the
    // window underneath and dismiss the panel instead of typing into it.
    function search(q: string): string { root.query = q; return String(root.rows.length) }
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
    focusTarget: searchField
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    // One Flickable around the whole column. A nested fillHeight Flickable
    // collapses to zero here, because the panel sizes itself from
    // column.implicitHeight and fillHeight has no height to fill yet.
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

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(12)
        Layout.leftMargin: Style.space(16)
        Layout.rightMargin: Style.space(16)
        spacing: Style.space(8)

        PanelSectionHeader {
          Layout.fillWidth: true
          text: root.dnd ? "Notifications — silenced" : "Notifications"
        }

        PanelActionButton {
          iconText: root.bellGlyph
          tooltipText: root.dnd ? "Allow notifications" : "Silence notifications"
          foreground: root.foreground
          fontFamily: root.fontFamily
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.toggleDnd()
        }

        PanelActionButton {
          iconText: "󰅙"
          tooltipText: "Clear notifications"
          foreground: root.foreground
          fontFamily: root.fontFamily
          // Hidden rather than disabled: with nothing to clear it is not a
          // control that is temporarily unavailable, it is one with no job.
          visible: root.hasRows || root.searching
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.clearAll()
        }
      }

      TextField {
        id: searchField
        Layout.fillWidth: true
        Layout.leftMargin: Style.space(16)
        Layout.rightMargin: Style.space(16)
        placeholderText: "Search notifications"
        foreground: root.foreground
        text: root.query
        onTextChanged: root.query = text
        Keys.onEscapePressed: {
          if (root.query !== "") root.query = ""
          else root.close()
        }
      }

      AppText {
        Layout.fillWidth: true
        Layout.leftMargin: Style.space(16)
        Layout.rightMargin: Style.space(16)
        Layout.topMargin: Style.space(8)
        Layout.bottomMargin: Style.space(16)
        visible: !root.hasRows
        text: root.searching ? "No matches." : "Nothing recent."
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      ColumnLayout {
          id: rowColumn
          Layout.fillWidth: true
          Layout.bottomMargin: Style.space(12)
          visible: root.hasRows
          spacing: Style.space(6)

          Repeater {
            model: root.rows

            delegate: BorderSurface {
              id: rowSurface
              required property var modelData

              Layout.fillWidth: true
              Layout.leftMargin: Style.space(12)
              Layout.rightMargin: Style.space(12)

              implicitHeight: rowContent.implicitHeight + Style.space(20)
              color: Color.notifications.background
              radius: Style.cornerRadius
              borderSpec: Border.surfaceSpec("notifications", "border",
                rowSurface.modelData.live ? Color.notifications.countdown : Color.notifications.border, 1)

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                // Left and right both dismiss: there is no reliable way to
                // invoke a notification's default action from an archived row,
                // so a click that silently does nothing would be worse.
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
}
