import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property string userName: ""
  property real shakeOffset: 0
  property string keyboardLabel: ""
  property string keyboardFull: ""

  readonly property string placeholderText: "Enter Password"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  onErrorStateChanged: if (errorState) shakeAnim.restart()
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
    refreshKeyboardLayout()
  }

  function refreshKeyboardLayout() {
    if (!keyboardQueryProc.running) keyboardQueryProc.running = true
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      if (String(event.name).indexOf("activelayout") !== -1) root.refreshKeyboardLayout()
    }
  }

  Process {
    id: keyboardQueryProc
    command: ["bash", "-lc", "hyprctl -j devices 2>/dev/null | sed -n '/keyboards/,$p' | head -200"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var match = String(text || "").match(/"active_keymap":\s*"([^"]+)"/)
        if (!match) return
        root.keyboardFull = match[1]
        root.keyboardLabel = match[1].split(/\s+/)[0].substring(0, 3).toUpperCase()
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refreshKeyboardLayout()
  }

  SequentialAnimation {
    id: shakeAnim
    NumberAnimation { target: root; property: "shakeOffset"; to: -14; duration: 50 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 14; duration: 50 }
    NumberAnimation { target: root; property: "shakeOffset"; to: -7; duration: 40 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 7; duration: 40 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 30 }
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Row {
      id: islands
      anchors {
        horizontalCenter: parent.horizontalCenter
        horizontalCenterOffset: root.shakeOffset
        verticalCenter: parent.verticalCenter
      }
      spacing: 10

      BorderSurface {
        id: leftIsland
        height: root.fieldHeight
        anchors.verticalCenter: parent.verticalCenter
        color: Color.lock.background
        borderSpec: Border.surfaceSpec("lock", "border", Color.lock.border, root.outlineThickness, "border-alpha")
        radius: Style.cornerRadius
        padding: 18
        implicitWidth: leftContent.implicitWidth + leftPadding + rightPadding + borderLeft + borderRight
        width: implicitWidth
        clip: true

        Row {
          id: leftContent
          anchors.centerIn: parent
          spacing: 8

          AppText {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
          }
          AppText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.userName
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
          }
          Rectangle {
            visible: root.keyboardLabel.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height * 0.5
            color: Color.lock.text
            opacity: 0.3
          }
          AppText {
            visible: root.keyboardLabel.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
          }
          AppText {
            visible: root.keyboardLabel.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.keyboardLabel
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
          }
        }
      }

    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      color: Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: Style.cornerRadius
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        anchors.rightMargin: inputField.borderRight + 18
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Color.lock.text
        selectionColor: Color.lock.selection
        selectedTextColor: Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? root.passwordDotFontSize : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      AppText {
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Color.lock.text : (root.failureMessage.length > 0 ? Color.lock.textError : Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
    }
  }
}
