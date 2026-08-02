import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "netspeed"

  property string curIface: ""
  property var prevRx: 0
  property var prevTx: 0
  property var prevTime: 0
  property real downRate: 0
  property real upRate: 0

  visible: curIface !== ""

  function formatRate(bps) {
    if (bps < 1024) return bps.toFixed(0) + " bps"
    var isMb = bps >= 1048576
    var value = isMb ? bps / 1048576 : bps / 1024
    var unit = isMb ? "mbps" : "kbps"
    return parseFloat(value.toFixed(1)) + " " + unit
  }

  function refresh() {
    if (!queryProc.running) queryProc.running = true
  }

  Process {
    id: queryProc
    command: ["omarchy-network-status", "--verbose"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var iface = ""
        var rx = 0
        var tx = 0
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (!line) continue
          var idx = line.indexOf("\t")
          if (idx === -1) continue
          var key = line.substring(0, idx)
          var val = line.substring(idx + 1).trim()
          if (key === "iface") iface = val
          else if (key === "rx_bytes") rx = parseFloat(val)
          else if (key === "tx_bytes") tx = parseFloat(val)
        }

        if (!iface) {
          root.curIface = ""
          return
        }

        root.curIface = iface
        var now = Date.now() / 1000

        if (root.prevTime > 0 && root.prevRx > 0) {
          var dt = now - root.prevTime
          if (dt > 0) {
            root.downRate = Math.max(0, (rx - root.prevRx) / dt)
            root.upRate = Math.max(0, (tx - root.prevTx) / dt)
          }
        }

        root.prevRx = rx
        root.prevTx = tx
        root.prevTime = now
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  implicitWidth: label.implicitWidth
  implicitHeight: barSize

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    leftPadding: Style.spaceReal(7.5)
    text: "󰇚 " + root.formatRate(root.downRate)
    color: root.bar ? root.bar.barForeground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    renderType: Text.NativeRendering
  }
}
