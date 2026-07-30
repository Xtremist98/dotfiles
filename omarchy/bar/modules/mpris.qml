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
      if (p.trackTitle || p.trackArtist) return p
    return null
  }

  function togglePlayPause() {
    if (player && player.canTogglePlaying)
      player.togglePlaying()
  }

  implicitWidth: Math.min(label.implicitWidth + Style.space(2), 180)
  implicitHeight: barSize

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    clip: true
    elide: Text.ElideRight

    readonly property var p: root.player
    readonly property string icon: p && p.isPlaying ? "󰐊 " : "󰏤 "
    readonly property string name: p ? p.identity : ""

    text: p ? icon + name : ""
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
