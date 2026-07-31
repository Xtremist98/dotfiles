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
      if (p.isPlaying && !isProxy(p)) return p
    for (let p of Mpris.players.values)
      if ((p.trackTitle || p.trackArtist) && !isProxy(p)) return p
    return null
  }

  function isProxy(p) {
    return (p.identity + " " + p.desktopEntry).toLowerCase().includes("playerctl")
  }

  function togglePlayPause() {
    if (player && player.canTogglePlaying)
      player.togglePlaying()
  }

  readonly property int maxWidth: 320
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var p: player
  readonly property bool isMpv: p ? (p.identity + " " + p.desktopEntry + " " + p.uniqueId).toLowerCase().includes("mpv") : false
  readonly property string name: p ? (isMpv && p.trackTitle ? p.trackTitle : p.identity) : ""

  implicitWidth: Math.min(content.implicitWidth + Style.space(2), maxWidth)
  implicitHeight: barSize

  TextMetrics {
    id: fontMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    text: "Ag"
  }

  Row {
    id: content
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(8)

    Text {
      id: icon
      anchors.verticalCenter: parent.verticalCenter
      text: root.p ? (root.p.isPlaying ? "󰐊" : "󰏤") : ""
      color: bar ? bar.barForeground : Color.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon
      renderType: Text.NativeRendering
    }

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, Math.min(root.maxWidth - icon.implicitWidth - content.spacing, implicitWidth))
      clip: true
      elide: Text.ElideRight
      lineHeight: fontMetrics.height
      lineHeightMode: Text.FixedHeight
      text: root.name
      color: bar ? bar.barForeground : Color.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.player !== null
    cursorShape: Qt.PointingHandCursor
    onClicked: root.togglePlayPause()
  }
}
