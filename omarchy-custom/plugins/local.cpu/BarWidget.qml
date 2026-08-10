pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Ui.Panel {
  id: root

  moduleName: "local.cpu"
  manageIpc: false

  readonly property var telemetry: localTelemetry
  LocalTelemetry { id: localTelemetry }
  readonly property var tokens: bar && "visualTokens" in bar
    ? bar.visualTokens : null
  readonly property color widgetInk: tokens
    && typeof tokens.widgetContentColor === "function"
    ? tokens.widgetGlyphColor(settings,
      bar ? bar.urgent : Commons.Color.accent)
    : (bar ? bar.urgent : Commons.Color.accent)
  readonly property var gpuTelemetry: gpuState
  GpuTelemetry {
    id: gpuState
    helperPath: String(Qt.resolvedUrl("scripts/gpu-probe")).replace("file://", "")
  }
  readonly property string displayMode: String(
    setting("displayMode", setting("compact", false) ? "icon" : "full"))
  readonly property bool compact: displayMode === "icon"
  readonly property int percent: telemetry ? telemetry.cpuPercent : 0
  property url panelSource: Qt.resolvedUrl("CpuPanel.qml")
  property var acquiredTelemetry: null

  implicitWidth: bar && bar.vertical ? bar.barSize : cpuSurface.implicitWidth
  implicitHeight: bar && bar.vertical ? cpuSurface.implicitHeight : bar ? bar.barSize : 28

  function syncTelemetryOwner() {
    if (acquiredTelemetry === telemetry) return
    if (acquiredTelemetry) acquiredTelemetry.release("cpu")
    acquiredTelemetry = telemetry
    if (acquiredTelemetry) acquiredTelemetry.acquire("cpu")
  }

  function syncPanelLoader() {
    if (!opened) {
      panelLoader.source = ""
      return
    }
    panelLoader.setSource(panelSource, {
      anchorItem: cpuSurface,
      bar: root.bar,
      ownerWidget: root,
      systemTelemetry: root.telemetry,
      gpuTelemetry: root.gpuTelemetry
    })
  }

  function openSystemMonitor() {
    if (!bar || typeof bar.run !== "function") return false
    bar.run("omarchy-launch-or-focus-tui btop")
    return true
  }

  onTelemetryChanged: syncTelemetryOwner()
  onOpenedChanged: syncPanelLoader()
  Component.onCompleted: syncTelemetryOwner()
  Component.onDestruction: if (acquiredTelemetry) acquiredTelemetry.release("cpu")

  Item {
    id: cpuSurface

    anchors.centerIn: parent
    implicitWidth: root.bar && root.bar.vertical
      ? root.bar.barSize
      : content.implicitWidth + 2 * root.tokens.pillPaddingX
    implicitHeight: root.bar && root.bar.vertical
      ? content.implicitHeight + Commons.Style.space(10)
      : root.tokens ? root.tokens.slotHeight : 28
    width: implicitWidth
    height: implicitHeight

    Loader {
      id: content
      anchors.centerIn: parent
      sourceComponent: root.bar && root.bar.vertical ? verticalContent : horizontalContent
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: if (root.bar) root.bar.showTooltip(cpuSurface, root.percent + "%")
      onExited: if (root.bar) root.bar.hideTooltip(cpuSurface)
      onClicked: {
        if (root.bar) root.bar.hideTooltip(cpuSurface)
        root.toggle()
      }
    }
  }

  Loader {
    id: panelLoader
  }

  Component {
    id: horizontalContent

    Row {
      spacing: root.tokens.compactGap

      IconText {
        visible: root.displayMode === "icon" || root.displayMode === "full"
        anchors.verticalCenter: parent.verticalCenter
        text: "planner_review"
        color: root.widgetInk
        font.pixelSize: root.tokens.iconSize
        font.weight: Font.DemiBold
        fill: 1
      }

      Text {
        visible: root.displayMode !== "icon"
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.percent).padStart(2, "0") + "%"
        color: root.widgetInk
        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
        font.pixelSize: root.tokens.labelSize
        renderType: Text.NativeRendering
      }
    }
  }

  Component {
    id: verticalContent

    Column {
      spacing: Commons.Style.space(2)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "CPU"
        color: Qt.rgba(root.widgetInk.r, root.widgetInk.g,
          root.widgetInk.b, 0.68)
        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
        font.pixelSize: Commons.Style.font.caption
        renderType: Text.NativeRendering
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(root.percent).padStart(2, "0") + "%"
        color: root.widgetInk
        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
        font.pixelSize: Commons.Style.font.caption
        renderType: Text.NativeRendering
      }
    }
  }
}
