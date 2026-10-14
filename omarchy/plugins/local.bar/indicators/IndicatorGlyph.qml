import QtQuick

// Indicator mark at a size of its own.
//
// The shared OpticalGlyph sets paintedSize to Style.bar.iconSize
// (Ui/BarIconButton.qml:75) and BarIconContent normalises whatever it loads
// to the same token, so a BarIndicator driven by `text:` can never render
// below that single global cap no matter what fontSize says. This draws the
// mark directly at pixelSize instead.
//
// The indicator keeps BarIndicator for its state, tooltip, hit area, block
// membership and reveal behaviour, and hides the built-in glyph by handing
// BarIconButton an empty iconComponent -- the same escape hatch omacore and
// the audio/bluetooth/monitor/power/system panels use. Opacity still comes
// from the indicator root, so dimmed and concealed states apply unchanged.
Text {
  id: root

  property real glyphSize: 12

  anchors.centerIn: parent
  textFormat: Text.PlainText
  font.pixelSize: glyphSize
  color: parent ? parent.foreground : "transparent"
  renderType: Text.CurveRendering
}