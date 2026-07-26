import QtQuick

// Drop-in Text replacement. Qt Quick's default renderType (QtRendering) skips
// hinting/pixel-snapping, so text looks softer than native GTK/Pango apps at
// the same size — NativeRendering matches that crispness everywhere.
Text {
  renderType: Text.NativeRendering
}
