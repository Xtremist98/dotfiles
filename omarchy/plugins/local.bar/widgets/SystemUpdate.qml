import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.system-update"

  readonly property color glyphColor: bar && bar.widgetGlyphColor
    ? bar.widgetGlyphColor(settings, bar.barForeground)
    : (bar ? bar.barForeground : Color.foreground)

  property bool updateAvailable: false

  function refresh() {
    if (!updateProc.running) updateProc.running = true
  }

  function clear() { updateAvailable = false }

  function runUpdate() {
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation omarchy-update")
  }

  visible: updateAvailable
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  IpcHandler {
    target: "omarchy.system-update"

    function refresh(): void {
      root.broadcast("refresh")
    }

    function clear(): void {
      root.broadcast("clear")
    }
  }

  Process {
    id: updateProc
    command: ["omarchy-update-available"]
    onExited: function(exitCode) {
      root.updateAvailable = exitCode === 0
    }
  }

  Timer {
    interval: 21600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // The network is often not ready yet at boot, so the startup check above
  // can miss an update that is already published. Retry with backoff for the
  // first few minutes after launch so the indicator appears once connectivity
  // comes up, instead of waiting up to 6 hours for the next periodic check.
  Timer {
    id: bootRetryTimer
    property int attempt: 0
    interval: 10000
    running: false
    repeat: false
    onTriggered: {
      if (root.updateAvailable) return
      root.refresh()
      attempt++
      if (attempt < 6) {
        interval = Math.min(480000, 10000 * Math.pow(2, attempt))
        running = true
      }
    }
  }

  Component.onCompleted: {
    bootRetryTimer.attempt = 0
    bootRetryTimer.interval = 10000
    bootRetryTimer.running = true
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: root.glyphColor
    text: "\uf021"
    slotSize: Style.bar.iconCanvas + Style.spaceReal(6) * 2
    fontSize: Style.bar.iconFont - 1
    tooltipText: "Pending Omarchy Updates"
    onPressed: root.runUpdate()
  }
}
