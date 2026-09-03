import QtQuick
import qs.Commons
import qs.Ui

// ThemedToggle: local replacement for qs.Ui.ToggleSwitch used by the
// local.bar audio/network/bluetooth panels.
//
// Renders the on/off switch in the classic pill shape regardless of Hyprland
// corner rounding (which local.bar sets to zero), and colors the active (on)
// state from the active theme's accent so it re-themes automatically on a
// theme switch, instead of following the [controls] selected-color token.
//
// Same public property/signal surface as the stock component so the panels
// use it unchanged, just under this distinct type name.
Item {
  id: root

  property bool checked: false
  property bool busy: false

  // Off when the surrounding row owns the click, as in `Toggle`.
  property bool interactive: true

  // Panel-cursor flag. Same role as Button.hasCursor.
  property bool hasCursor: false

  property bool cursorRing: interactive
  property int cursorPad: Style.space(6)
  property color foreground: Color.foreground
  property color accent: Color.accent

  signal toggled()
  signal hovered(bool isHovered)

  readonly property alias containsMouse: mouse.containsMouse
  readonly property bool hot: hasCursor || mouse.containsMouse

  property int trackHeight: Math.max(22, Math.round(Style.spacing.controlHeight * 0.55))
  property int trackWidth: Math.round(trackHeight * 1.9)
  property int knobSize: Math.max(6, Math.round(trackHeight * 0.72))
  property int knobInset: Math.max(1, Math.round((trackHeight - knobSize) / 2))

  readonly property int _pad: cursorRing ? cursorPad : 0

  // Readable knob on the accent track: dark knob on light accents, light knob
  // on dark accents, so the pill reads as on at a glance in any theme.
  readonly property color onKnobColor: {
    var c = Qt.color(root.accent)
    var lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    return lum > 0.5 ? Qt.rgba(0.08, 0.08, 0.1, 1.0) : Qt.rgba(1.0, 1.0, 1.0, 1.0)
  }

  implicitWidth: trackWidth + _pad * 2
  implicitHeight: trackHeight + _pad * 2

  BorderSurface {
    anchors.fill: parent
    visible: root.cursorRing && root.hot
    color: "transparent"
    radius: Style.cornerRadius
    borderSpec: Border.controlSpec("hover-cursor", root.foreground, root.accent)
  }

  BorderSurface {
    id: track
    width: root.trackWidth
    height: root.trackHeight
    anchors.centerIn: parent
    // Always a pill, regardless of Hyprland corner rounding.
    radius: height / 2
    color: root.checked
      ? root.accent
      : Style.normalFillFor(root.foreground, root.accent)
    borderSpec: Border.controlSpec(root.checked ? "selected" : "normal", root.foreground, root.accent)

    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
      width: root.knobSize
      height: root.knobSize
      radius: height / 2
      x: root.checked ? track.width - width - root.knobInset : root.knobInset
      anchors.verticalCenter: parent.verticalCenter
      color: root.checked
        ? root.onKnobColor
        : Qt.darker(root.foreground, 1.25)

      Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 120 } }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: if (!root.busy) root.toggled()
  }
}
