import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

// Bar media pill (play/pause icon + now-playing title) that opens a panel
// styled after the user's old MprisPanel.qml: NOW PLAYING header with the
// active player name and a close button, album art + track info, a live
// progress bar, and prev/play/next controls.
Panel {
  id: root
  moduleName: "mpris"
  ipcTarget: "mpris"

  readonly property int barSize: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

  // ------------------------------------------------------------- player

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

  function playPrevious() {
    if (player && player.canGoPrevious) player.previous()
  }

  function playNext() {
    if (player && player.canGoNext) player.next()
  }

  // ----------------------------------------------------- pill elide bounds

  function sceneX(item) {
    var x = item.x
    var p = item.parent
    while (p) {
      x += p.x
      p = p.parent
    }
    return x
  }

  function centerLeftEdge() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return -1
    var slots = bar.moduleSlots
    var left = -1
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.region === "center" && s.visible === true && s.width > 0) {
        var x = root.sceneX(s)
        if (left < 0 || x < left) left = x
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
      if (s && s.activeItem === root) return root.sceneX(s)
    }
    return 0
  }

  // The window-info widget sits right after this module in the left region, so
  // whenever it will paint a focused-window title we must stay compact and
  // leave it room instead of stretching all the way to the center section.
  readonly property bool windowInfoVisible: root.windowInfoShown()

  function windowInfoShown() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return false
    var slots = bar.moduleSlots
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.region === "left" && s.activeItem && s.activeItem.moduleName === "window-info")
        return s.activeItem.visible === true
    }
    return false
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
  readonly property int maxWidth: root.isMpv
    ? (root.windowInfoVisible ? 320 : root.mpvMaxWidth)
    : 320
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var p: player
  readonly property bool isMpv: p ? (p.identity + " " + p.desktopEntry + " " + p.uniqueId).toLowerCase().includes("mpv") : false
  readonly property string name: p ? (isMpv && p.trackTitle ? p.trackTitle : p.identity) : ""

  readonly property string playerName: p ? (p.identity || p.desktopEntry || "Media Player").replace(/^org\.mpris\.MediaPlayer2\./, "") : ""
  readonly property bool playing: p ? p.isPlaying : false

  // --------------------------------------------------------- panel palette

  readonly property color ink: bar ? bar.barForeground : Color.foreground
  readonly property string mono: bar ? bar.fontFamily : Style.font.family
  readonly property color seal: Color.accent
  readonly property color sumi: Qt.darker(ink, 1.55)
  readonly property color sumiHi: Qt.darker(ink, 1.35)
  readonly property color sep: Qt.alpha(ink, 0.18)
  readonly property color fillActive: Qt.alpha(seal, 0.16)

  // ------------------------------------------------------- live position

  property real curPos: 0
  property real curLen: 0
  property real _lastRead: -1

  Timer {
    interval: 500
    repeat: true
    running: root.opened && root.p !== null
    triggeredOnStart: true
    onTriggered: {
      if (!root.p) return
      var pos = root.p.position || 0
      root.curLen = root.p.length || 0
      if (Math.abs(pos - root._lastRead) > 0.05) {
        root.curPos = pos
        root._lastRead = pos
      } else if (root.p.isPlaying) {
        var cap = root.curLen > 0 ? root.curLen : pos + 1e9
        root.curPos = Math.min(cap, root.curPos + 0.5)
      }
    }
  }
  onPlayingChanged: root._lastRead = -1

  function fmtTime(s) {
    if (!s || s < 0) return "0:00"
    var m = Math.floor(s / 60)
    var sec = Math.floor(s % 60)
    return m + ":" + (sec < 10 ? "0" + sec : "" + sec)
  }

  // ------------------------------------------------------------- bar pill

  readonly property string playIcon: p ? (p.isPlaying ? "󰐊" : "󰏤") : "󰐊"

  implicitWidth: Math.min(content.implicitWidth + Style.space(2) + Style.spaceReal(7.5) * 2, maxWidth)
  implicitHeight: barSize

  visible: player !== null

  Row {
    id: content
    anchors.left: parent.left
    anchors.leftMargin: Style.spaceReal(7.5)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(8)

    Text {
      id: icon
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 1
      text: root.playIcon
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: 13
      renderType: Text.NativeRendering
    }

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, Math.min(root.maxWidth - icon.implicitWidth - content.spacing, implicitWidth))
      clip: true
      elide: Text.ElideRight
      text: root.name
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.player !== null
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) root.togglePlayPause()
      else if (mouse.button === Qt.RightButton) root.toggle()
    }
    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) root.playPrevious()
      else if (wheel.angleDelta.y < 0) root.playNext()
    }
  }

  // ------------------------------------------------------------- dropdown

  KeyboardPanel {
    id: panel
    anchorItem: content
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    padding: Style.space(12)
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(8)

        // ---------- header: NOW PLAYING · player name · close ----------
        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "NOW PLAYING"
            color: root.ink
            font.family: root.mono
            font.pixelSize: Style.font.subtitle
            font.letterSpacing: 2
            font.weight: Font.Medium
            renderType: Text.NativeRendering
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: root.p !== null && root.playerName !== ""
              text: root.playerName
              color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)
              font.family: root.mono
              font.pixelSize: Style.font.body
              font.letterSpacing: 1
              renderType: Text.NativeRendering
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "✕"
              color: closeMa.containsMouse ? root.seal : root.sumi
              font.family: root.mono
              font.pixelSize: Style.font.body
              Behavior on color { ColorAnimation { duration: 120 } }
              MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: root.sep }

        // ---------- album art + track info ----------
        Row {
          width: parent.width
          spacing: Style.space(10)
          visible: root.p !== null

          Rectangle {
            width: Style.space(52)
            height: Style.space(52)
            radius: 5
            color: root.fillActive
            clip: true

            Image {
              anchors.fill: parent
              source: root.p ? (root.p.trackArtUrl || "") : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: !root.p || root.p.trackArtUrl === ""
              text: "󰝚"
              font.family: root.mono
              font.pixelSize: Style.space(26)
              color: root.seal
              renderType: Text.NativeRendering
            }
          }

          Column {
            width: parent.width - Style.space(62)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3)

            Text {
              width: parent.width
              text: root.p ? (root.p.trackTitle || "Unknown") : ""
              color: root.ink
              font.family: root.mono
              font.pixelSize: Style.font.body
              font.weight: Font.Medium
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }

            Text {
              width: parent.width
              text: root.p ? (root.p.trackArtist || "") : ""
              color: root.sumiHi
              font.family: root.mono
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              visible: text !== ""
              renderType: Text.NativeRendering
            }

            Text {
              width: parent.width
              text: root.p ? (root.p.trackAlbum || "") : ""
              color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)
              font.family: root.mono
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              visible: text !== ""
              renderType: Text.NativeRendering
            }
          }
        }

        // ---------- progress bar (only when the player reports a length) --
        Item {
          width: parent.width
          height: Style.space(14)
          visible: root.p !== null && root.curLen > 0

          Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 4
            radius: 2
            color: root.fillActive

            Rectangle {
              height: parent.height
              radius: 2
              color: root.seal
              width: parent.width * (root.curLen > 0
                ? Math.min(1, root.curPos / root.curLen) : 0)
              Behavior on width { NumberAnimation { duration: 450 } }
            }
          }

          Text {
            anchors.left: parent.left
            anchors.top: track.bottom
            anchors.topMargin: 2
            text: root.fmtTime(root.curPos)
            color: root.sumiHi
            font.family: root.mono
            font.pixelSize: 9
            renderType: Text.NativeRendering
          }

          Text {
            anchors.right: parent.right
            anchors.top: track.bottom
            anchors.topMargin: 2
            text: root.fmtTime(root.curLen)
            color: root.sumiHi
            font.family: root.mono
            font.pixelSize: 9
            renderType: Text.NativeRendering
          }
        }

        // ---------- no-song message ----------
        Item {
          width: parent.width
          height: Style.space(36)
          visible: root.p === null

          Column {
            anchors.centerIn: parent
            spacing: Style.space(1)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "No song playing"
              color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.55)
              font.family: root.mono
              font.pixelSize: Style.font.body
              font.weight: Font.Medium
              renderType: Text.NativeRendering
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "no active player"
              color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.3)
              font.family: root.mono
              font.pixelSize: Style.font.caption
              renderType: Text.NativeRendering
            }
          }
        }

        // ---------- controls ----------
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(18)
          visible: root.p !== null

          Text {
            text: "󰒮"
            font.family: root.mono
            font.pixelSize: Style.space(20)
            anchors.verticalCenter: parent.verticalCenter
            color: (root.p && root.p.canGoPrevious) ? root.ink : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.25)
            renderType: Text.NativeRendering
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.p) root.p.previous()
            }
          }

          Text {
            text: root.p && root.p.isPlaying ? "󰏤" : "󰐊"
            font.family: root.mono
            font.pixelSize: Style.space(24)
            anchors.verticalCenter: parent.verticalCenter
            color: root.seal
            renderType: Text.NativeRendering
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.p) root.p.togglePlaying()
            }
          }

          Text {
            text: "󰒭"
            font.family: root.mono
            font.pixelSize: Style.space(20)
            anchors.verticalCenter: parent.verticalCenter
            color: (root.p && root.p.canGoNext) ? root.ink : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.25)
            renderType: Text.NativeRendering
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.p) root.p.next()
            }
          }
        }
      }
    }
  }
}
