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

  function centerLeftEdge() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return -1
    var slots = bar.moduleSlots
    var left = -1
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.region === "center" && s.visible === true && s.width > 0) {
        if (left < 0 || s.x < left) left = s.x
      }
    }
    return left
  }

  function mySlotX() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return 0
    var slots = bar.moduleSlots
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.moduleName === "mpris" && s.region === "left") return s.x
    }
    return 0
  }

  readonly property int mpvMaxWidth: {
    var left = root.centerLeftEdge()
    var slotX = root.mySlotX()
    if (left > 0) {
      var avail = Math.floor(left - slotX) - Style.space(20)
      return Math.max(240, Math.min(1500, avail))
    }
    return bar && bar.width > 0
      ? Math.min(1500, Math.max(240, Math.floor(bar.width / 2) - Style.space(480)))
      : 480
  }
  readonly property int maxWidth: root.isMpv ? root.mpvMaxWidth : 320
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
