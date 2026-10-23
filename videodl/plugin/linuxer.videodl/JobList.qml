import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// A titled stack of JobRow cards. The downloads view and the finished view each
// use one of these, so the heading, the empty text and the row wiring exist once.
Column {
  id: root

  property var jobs: []
  property var service: null
  property double now: Date.now()
  property string heading: ""
  property string emptyText: ""
  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property string fontFamily: ""

  width: parent ? parent.width : 0
  spacing: Style.space(6)

  PanelSectionHeader {
    width: parent.width
    visible: text !== ""
    text: root.heading
    foreground: root.foreground
    fontFamily: root.fontFamily
  }

  Text {
    width: parent.width
    visible: text !== ""
    text: root.jobs.length === 0 ? root.emptyText : ""
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: Qt.darker(root.foreground, 1.5)
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  // An integer model on purpose. `model: root.jobs` would reset the view every
  // time the service publishes a new array (which it does on every poll), and a
  // reset destroys and rebuilds every delegate: the progress line restarts at
  // zero, the thumbnail reloads, hover and focus are lost. With a count, the
  // delegates keep their identity and only re-read the record assigned to them.
  Repeater {
    model: root.jobs ? root.jobs.length : 0

    JobRow {
      required property int index

      width: root.width
      job: root.jobs && index < root.jobs.length ? root.jobs[index] : null
      service: root.service
      now: root.now
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
    }
  }
}
