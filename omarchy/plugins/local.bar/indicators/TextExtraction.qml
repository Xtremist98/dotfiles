import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  fontSize: Style.bar.iconFont - 1

  property bool capturing: false

  active: capturing
  activeText: "󰴑"
  inactiveText: "󰴑"
  activeTooltipText: "Extracting text… (click to cancel)"
  inactiveTooltipText: "Extract text from screen"

  function refresh() {
    if (!root.bar || statusProc.running) return
    statusProc.command = ["pgrep", "--quiet", "-f", "[o]marchy-capture-text"]
    statusProc.running = true
  }

  onBarChanged: refresh()
  Component.onCompleted: refresh()

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() { root.refresh() }
  }

  Timer {
    id: pollTimer
    interval: 400
    running: root.bar != null
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    onExited: function(exitCode) {
      root.capturing = exitCode === 0
    }
  }

  onPressed: function() {
    if (!root.bar) return
    if (root.capturing) {
      root.bar.run("pkill -f '[o]marchy-capture-text'; pkill -x slurp")
    } else {
      root.bar.run("omarchy-capture-text")
    }
  }
}
