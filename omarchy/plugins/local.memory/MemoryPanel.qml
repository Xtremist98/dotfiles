pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Panel {
  id: panel

  required property var ownerWidget
  required property var telemetry

  owner: ownerWidget
  open: ownerWidget.opened
  focusTarget: keyCatcher
  padding: 12
  contentWidth: fittedContentWidth(320)
  contentHeight: fittedContentHeight(panelColumn.implicitHeight)

  Ui.PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent
    onCloseRequested: panel.ownerWidget.close()
    onTabRequested: function(direction) { panel.ownerWidget.switchPanel(direction) }

    Column {
      id: panelColumn
      width: parent.width
      spacing: 8

      Item {
        width: parent.width
        height: 24

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Memory"
          color: panel.controlForeground
          font.family: panel.bar ? panel.bar.fontFamily : Commons.Style.font.family
          font.pixelSize: 13
          font.letterSpacing: 2
          font.weight: Font.Medium
          renderType: Text.NativeRendering
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "\u2715"
          color: closeMouse.containsMouse
            ? panel.controlAccent : panel.controlMuted
          font.family: panel.bar ? panel.bar.fontFamily
            : Commons.Style.font.family
          font.pixelSize: 12
          renderType: Text.NativeRendering

          Behavior on color { ColorAnimation { duration: 120 } }

          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.ownerWidget.close()
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Commons.Util.alpha(panel.controlForeground, 0.18)
      }

      Item {
        width: parent.width
        height: 30

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          text: panel.telemetry.memPercent + "%"
          color: panel.controlAccent
          font.family: panel.bar ? panel.bar.fontFamily
            : Commons.Style.font.family
          font.pixelSize: 11
          font.weight: Font.Medium
          renderType: Text.NativeRendering
        }

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: 8
          radius: height / 2
          color: panel.controlActiveFillColor

          Rectangle {
            width: parent.width * panel.telemetry.memPercent / 100
            height: parent.height
            radius: height / 2
            color: panel.controlAccent
            Behavior on width { NumberAnimation { duration: 300 } }
          }
        }
      }

      Column {
        width: parent.width
        spacing: 4

        MemoryStatRow {
          width: parent.width
          label: "Used"
          value: panel.telemetry.memUsedGiB.toFixed(1) + " GiB"
          detail: panel.telemetry.memUsedMiB + " MiB"
          bar: panel.bar
        }
        MemoryStatRow {
          width: parent.width
          label: "Available"
          value: (panel.telemetry.memAvailableMiB / 1024).toFixed(1) + " GiB"
          detail: panel.telemetry.memAvailableMiB + " MiB"
          bar: panel.bar
        }
        MemoryStatRow {
          width: parent.width
          label: "Total"
          value: panel.telemetry.memTotalGiB.toFixed(1) + " GiB"
          detail: panel.telemetry.memTotalMiB + " MiB"
          bar: panel.bar
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: panel.dividerColor
      }

      Rectangle {
        width: parent.width
        height: 28
        radius: panel.controlRadius
        color: monitorMouse.containsMouse
          ? panel.controlPrimaryHoverColor
          : panel.controlAccent

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          text: "Open btop"
          color: Commons.Color.background
          font.family: panel.bar ? panel.bar.fontFamily : Commons.Style.font.family
          font.pixelSize: 11
          renderType: Text.NativeRendering
        }

        MouseArea {
          id: monitorMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.ownerWidget.close()
            panel.ownerWidget.openSystemMonitor()
          }
        }
      }
    }
  }

  component MemoryStatRow: Row {
    required property string label
    required property string value
    required property string detail
    required property var bar

    Text {
      id: labelText
      width: parent.width * 0.4
      text: parent.label
      color: Commons.Util.alpha(panel.controlForeground, 0.65)
      font.family: parent.bar ? parent.bar.fontFamily : Commons.Style.font.family
      font.pixelSize: 11
      renderType: Text.NativeRendering
    }
    Text {
      id: valueText
      width: parent.width * 0.3
      text: parent.value
      color: panel.controlForeground
      font.family: parent.bar ? parent.bar.fontFamily : Commons.Style.font.family
      font.pixelSize: 11
      renderType: Text.NativeRendering
    }
    Text {
      id: detailText
      width: parent.width * 0.3
      text: parent.detail
      color: Commons.Util.alpha(panel.controlForeground, 0.58)
      font.family: parent.bar ? parent.bar.fontFamily : Commons.Style.font.family
      font.pixelSize: 11
      renderType: Text.NativeRendering
    }
  }
}
