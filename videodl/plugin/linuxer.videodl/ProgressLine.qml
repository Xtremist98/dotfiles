import QtQuick
import qs.Commons
import qs.Commons as Commons

// One continuous progress line: a rounded track with a rounded fill on top.
// It grows smoothly with the transfer instead of jumping between blocks, so a
// slow download still reads as "moving" without pretending to be chunked.
Item {
  id: root

  // 0-100.
  property real value: 0
  property real thickness: Style.space(4)
  property color fillColor: Commons.Color.accent
  // Matching the poll interval makes the fill travel at a constant speed
  // instead of arriving early and standing still until the next sample.
  property int animationDuration: 800

  implicitHeight: thickness
  readonly property real ratio: Math.max(0, Math.min(1, (Number(value) || 0) / 100))
  // Never let a sliver of fill round to nothing: one dot of colour is the
  // difference between "starting" and "not responding".
  readonly property real fillWidth: ratio > 0
    ? Math.max(root.height, root.width * root.ratio)
    : 0

  Behavior on value {
    NumberAnimation {
      duration: Math.max(120, root.animationDuration)
      easing.type: Easing.Linear
    }
  }

  Rectangle {
    id: track

    anchors.fill: parent
    radius: height / 2
    color: Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.16)
  }

  Rectangle {
    id: fill

    width: Math.min(root.fillWidth, track.width)
    height: track.height
    radius: height / 2
    color: root.fillColor
    visible: width > 0
  }
}
