import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mpris"

  readonly property var player: activePlayer()

  function activePlayer() {
    for (let p of Mpris.players.values)
      if (p.isPlaying) return p
    for (let p of Mpris.players.values)
      if (p.canPlay) return p
    return null
  }

  function togglePlayPause() {
    if (player && player.canTogglePlaying)
      player.togglePlaying()
  }

  visible: player !== null
  implicitWidth: player ? label.implicitWidth + Style.space(2) : 0
  implicitHeight: barSize

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter

    readonly property var p: root.player
    readonly property string icon: p && p.isPlaying ? "󰐊" : "󰏤"
    readonly property string name: p ? p.identity : ""
    readonly property string sep: p ? " " : ""

    text: p ? icon + sep + name : ""
    color: root.bar ? root.bar.barForeground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    renderType: Text.NativeRendering
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.player !== null
    cursorShape: Qt.PointingHandCursor
    onClicked: root.togglePlayPause()
  }
}
