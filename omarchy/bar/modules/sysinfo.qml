import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: rootModule

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  property int cpuPct: 0
  property int memPct: 0
  property int swapPct: 0
  property int diskPct: 0
  property int memTotal: 0
  property int memAvail: 0
  property int memFree: 0
  property int swapTotal: 0
  property int swapFree: 0
  property int diskUsed: 0
  property int diskTotal: 0
  property var processes: []
  property string uptime: ""

  property bool showInfo: false

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family
  readonly property string scriptPath: Quickshell.env("HOME") + "/.config/omarchy/scripts/sysinfo.sh"

  implicitWidth: label.implicitWidth + Style.spaceReal(7.5) * 2
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  Text {
    id: label
    anchors.centerIn: parent
    text: "󰻠 " + rootModule.cpuPct + "%  󰍛 " + rootModule.memPct + "%"
    color: bar ? bar.barForeground : Color.foreground
    font.family: rootModule.fontFam
    font.pixelSize: Style.bar.iconFont - 1
    renderType: Text.NativeRendering
  }

  Process {
    id: dataProc
    command: ["bash", rootModule.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: rootModule.parseData(text)
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!dataProc.running)
        dataProc.running = true
    }
  }

  function parseData(raw) {
    try {
      var d = JSON.parse(raw)
      rootModule.cpuPct = Number(d.cpu) || 0
      rootModule.memPct = Number(d.memPercent) || 0
      rootModule.swapPct = Number(d.swapPercent) || 0
      rootModule.diskPct = Number(d.diskPercent) || 0
      rootModule.memTotal = Number(d.memTotal) || 0
      rootModule.memAvail = Number(d.memAvail) || 0
      rootModule.memFree = Number(d.memFree) || 0
      rootModule.swapTotal = Number(d.swapTotal) || 0
      rootModule.swapFree = Number(d.swapFree) || 0
      rootModule.diskUsed = Number(d.diskUsed) || 0
      rootModule.diskTotal = Number(d.diskTotal) || 0
      rootModule.processes = Array.isArray(d.processes) ? d.processes : []
      rootModule.uptime = String(d.uptime || "")
    } catch (e) {}
  }

  function fmt(kb) {
    var v = kb
    for (var unit of ['KB', 'MB', 'GB', 'TB']) {
      if (v < 1024) return v.toFixed(1) + unit
      v /= 1024
    }
    return v.toFixed(1) + "TB"
  }

  function barStr(len, pct) {
    var filled = Math.round(len * pct / 100)
    return "■".repeat(filled) + "□".repeat(len - filled)
  }

  function close() {
    rootModule.showInfo = false
  }

  PopupCard {
    id: infoPopup
    anchorItem: rootModule
    bar: rootModule.bar
    owner: rootModule
    open: rootModule.showInfo
    triggerMode: "click"
    contentWidth: fittedContentWidth(Style.space(360))
    contentHeight: fittedContentHeight(infoColumn.implicitHeight)

    Column {
      id: infoColumn
      anchors.fill: parent
      spacing: Style.space(4)

      Text {
        width: parent.width
        text: rootModule.buildTooltipHtml()
        color: Color.popups.text
        font.family: rootModule.fontFam
        font.pixelSize: Style.font.body
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignTop
        lineHeight: 1.3
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (!rootModule.bar) return
      if (mouse.button === Qt.LeftButton) {
        rootModule.showInfo = !rootModule.showInfo
      } else if (mouse.button === Qt.RightButton) {
        rootModule.bar.run("omarchy-launch-or-focus-tui btop")
        if (rootModule.showInfo) rootModule.showInfo = false
      }
    }
  }

  function buildTooltipHtml() {
    var memUsed = rootModule.memTotal - rootModule.memAvail
    var topApps = rootModule.processes
    var lines = []

    lines.push("CPU     [" + rootModule.barStr(10, rootModule.cpuPct) + "] " + rootModule.cpuPct + "%")
    lines.push("MEMORY  [" + rootModule.barStr(10, rootModule.memPct) + "] " + rootModule.memPct + "%")
    lines.push("         Used: " + rootModule.fmt(memUsed).padEnd(10) + " Free: " + rootModule.fmt(rootModule.memAvail))
    lines.push("SWAP    [" + rootModule.barStr(10, rootModule.swapPct) + "] " + rootModule.swapPct + "%")
    lines.push("DISK    [" + rootModule.barStr(10, rootModule.diskPct) + "] " + rootModule.diskPct + "%")
    lines.push("         Used: " + rootModule.fmt(rootModule.diskUsed).padEnd(10) + " Total: " + rootModule.fmt(rootModule.diskTotal))
    lines.push("")
    lines.push("ACTIVE TASKS")

    for (var i = 0; i < Math.min(topApps.length, 8); i++) {
      var p = topApps[i]
      var appName = String(p.name || "").toUpperCase().substring(0, 15)
      var dots = ".".repeat(Math.max(1, 22 - appName.length))
      var memStr = rootModule.fmt(Number(p.rss) || 0).padStart(8)
      lines.push("  " + appName + " " + dots + " " + memStr)
    }

    lines.push("")
    lines.push("UPTIME: " + rootModule.uptime)

    return lines.join("\n")
  }
}
