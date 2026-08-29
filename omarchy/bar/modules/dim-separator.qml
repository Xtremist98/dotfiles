import QtQuick
import qs.Commons

Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: null

  implicitWidth: Style.space(1)
  implicitHeight: bar ? bar.barSize : 28

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: Style.space(0)
    width: 1
    height: Math.min(parent.height - 14, 12)
    color: bar ? bar.barForeground : Color.foreground
    opacity: 0.16
  }
}
