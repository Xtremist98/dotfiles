import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// Bar icon plus popup for downloads started from the Video Grabber extension.
//
// The extension itself never shows progress: it hands the job to the native
// host and closes. Everything about the transfer - segmented progress, rates,
// remaining time, the finished file - is reported here, by the host's own job
// records, so it stays readable after the tab that started it is gone.
Panel {
  id: root

  moduleName: "linuxer.videodl"
  ipcTarget: "videodl"

  // Ui.Panel is a bare Item, so without these the bar's ModuleSlot (which sizes
  // itself from activeItem.implicitWidth) collapses to zero and the icon never
  // gets a slot to paint in.
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Polling lives in the service so the icon in the bar and this panel agree on
  // one source of truth. Fast while something is downloading or the panel is
  // open, slow when the desktop is idle.
  Service {
    id: service
    open: root.opened
    activeInterval: Math.max(500, Number(root.setting("pollActiveSec", 2)) * 1000)
    idleInterval: Math.max(2000, Number(root.setting("pollIdleSec", 20)) * 1000)
  }

  // Ui.Panel already declares `settings`, so the bar's injectProps fills it in.
  // The icon takes its layout swatch (shell.json "color"), the panel takes the
  // bar's panel ink - the same split every other widget here uses.
  readonly property color glyphColor: bar && bar.widgetGlyphColor && settings
    ? bar.widgetGlyphColor(settings, bar.foreground)
    : (bar ? bar.foreground : Commons.Color.foreground)
  readonly property color ink: bar && bar.panelForeground !== undefined
    ? bar.panelForeground
    : Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: Commons.Color.urgent
  readonly property color dim: Qt.darker(ink, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int maxCompleted: Math.max(0, Number(setting("maxCompleted", 12)) || 0)

  readonly property var split: Model.split(service.jobs)
  readonly property var activeList: split.active
  readonly property var doneList: split.done.slice(0, maxCompleted)
  // Terminal jobs worth browsing. maxCompleted === 0 means "no finished list at
  // all", so the switch below disappears instead of opening onto nothing.
  readonly property int finishedTotal: maxCompleted > 0 ? service.doneJobs.length : 0
  readonly property real progress: Model.activeProgress(service.jobs)
  readonly property string tooltip: Model.summary(service.jobs)

  // One pane, two views. The finished list is the same panel showing the same
  // rows, reached from the switch under the live downloads, so a quiet panel
  // stays only as tall as the transfers it is actually reporting.
  property string view: "downloads"
  readonly property bool finishedView: view === "finished"

  function clearCompleted() {
    if (finishedView) view = "downloads"
    service.clearCompleted()
  }

  function toggleView() {
    if (finishedView) view = "downloads"
    else if (finishedTotal > 0) view = "finished"
  }

  // Reopening the panel always starts on the live list.
  onOpenedChanged: if (!opened) view = "downloads"

  BarIconButton {
    id: button
    bar: root.bar
    foreground: root.glyphColor
    active: service.busy
    tooltipText: root.tooltip
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) service.refresh()
      else root.toggle()
    }

    // Idle, the slot is the ordinary download arrow so it reads like every
    // other icon in the bar. While a transfer is in flight it becomes a
    // progress ring instead: 12px is not enough room for a ring *and* a glyph
    // (the inner diameter is only ~7.7px once the stroke is subtracted), so
    // the ring carries the state rather than being drawn around an arrow.
    iconComponent: Component {
      Item {
        width: Style.bar.iconSize
        height: Style.bar.iconSize

        Canvas {
          id: ring
          anchors.fill: parent
          visible: service.busy
          property real progress: root.progress

          onProgressChanged: requestPaint()
          onVisibleChanged: requestPaint()
          Component.onCompleted: requestPaint()

          onPaint: {
            var context = getContext("2d")
            context.clearRect(0, 0, width, height)
            var center = width / 2
            var radius = width / 2 - 1.2
            if (radius <= 0) return
            var ratio = Math.max(0, Math.min(1, progress / 100))
            var start = -Math.PI / 2

            context.lineWidth = 1.5
            context.lineCap = "round"
            context.beginPath()
            context.arc(center, center, radius, 0, Math.PI * 2)
            context.strokeStyle = Qt.rgba(root.glyphColor.r, root.glyphColor.g,
              root.glyphColor.b, 0.26)
            context.stroke()

            if (ratio > 0.001) {
              context.beginPath()
              context.arc(center, center, radius, start, start + Math.PI * 2 * ratio)
              context.strokeStyle = root.accent
              context.stroke()
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: !service.busy
          text: Model.GLYPH_DOWNLOAD
          textFormat: Text.PlainText
          color: root.glyphColor
          font.family: root.fontFamily
          font.pixelSize: Style.bar.iconFont
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      // Esc is "one step back": the finished view returns to the downloads
      // first, and only a second Esc closes the panel.
      onCloseRequested: if (root.finishedView) root.view = "downloads"
        else root.close()
      // Enter toggles the finished view, the same thing the switch under the
      // live rows does with a click.
      onReturnRequested: root.toggleView()
      onTextKey: function(text) {
        if (text === "r" || text === "R") service.refresh()
        else if (text === "c" || text === "C") root.clearCompleted()
        else if (text === "f" || text === "F") root.toggleView()
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(10)

          // Live view.
          PanelHero {
            width: parent.width
            visible: !root.finishedView
            title: "Video Grabber"
            meta: Model.summary(service.jobs)
            foreground: root.ink
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                text: Model.GLYPH_DOWNLOAD
                textFormat: Text.PlainText
                color: root.ink
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }

            trailingControl: Component {
              Row {
                spacing: Style.space(2)

                PanelActionButton {
                  iconText: Model.GLYPH_SWEEP
                  tooltipText: "Clear finished downloads"
                  foreground: root.ink
                  fontFamily: root.fontFamily
                  enabled: Model.completedCount(service.doneJobs) > 0
                  onClicked: root.clearCompleted()
                }

                PanelActionButton {
                  iconText: Model.GLYPH_REFRESH
                  tooltipText: "Refresh"
                  foreground: root.ink
                  fontFamily: root.fontFamily
                  enabled: !service.refreshing
                  onClicked: service.refresh()
                }
              }
            }
          }

          // Finished view: the same panel, showing the files that are no longer
          // moving. The hero carries the way back so Esc is never the only exit.
          PanelHero {
            width: parent.width
            visible: root.finishedView
            title: "Finished"
            meta: root.finishedTotal === 1 ? "1 download" : root.finishedTotal + " downloads"
            foreground: root.ink
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                text: Model.GLYPH_CHECK
                textFormat: Text.PlainText
                color: root.ink
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }

            trailingControl: Component {
              Row {
                spacing: Style.space(2)

                PanelActionButton {
                  iconText: Model.GLYPH_BACK
                  tooltipText: "Back to downloads"
                  foreground: root.ink
                  fontFamily: root.fontFamily
                  onClicked: root.view = "downloads"
                }

                PanelActionButton {
                  iconText: Model.GLYPH_SWEEP
                  tooltipText: "Clear finished downloads"
                  foreground: root.ink
                  fontFamily: root.fontFamily
                  enabled: Model.completedCount(service.doneJobs) > 0
                  onClicked: root.clearCompleted()
                }

                PanelActionButton {
                  iconText: Model.GLYPH_REFRESH
                  tooltipText: "Refresh"
                  foreground: root.ink
                  fontFamily: root.fontFamily
                  enabled: !service.refreshing
                  onClicked: service.refresh()
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: text !== ""
            text: service.lastError !== "" ? service.lastError : service.actionNote
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: service.lastError !== "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Column {
            width: parent.width
            visible: !root.finishedView
            spacing: Style.space(10)

            JobList {
              width: parent.width
              heading: "Downloading"
              jobs: root.activeList
              service: service
              now: service.now
              foreground: root.ink
              accent: root.accent
              fontFamily: root.fontFamily
              emptyText: service.loaded
                ? "Nothing in flight. Hover a video and pick a quality to start one."
                : "Looking for downloads…"
            }

            // The finished list is one click away rather than permanently on
            // screen, so the panel stays as short as what it is reporting.
            BorderSurface {
              id: finishedButton
              width: parent.width
              height: Style.space(34)
              visible: root.finishedTotal > 0
              radius: Style.cornerRadius
              readonly property bool hot: finishedMouse.containsMouse
              color: hot ? Style.hoverFillFor(root.ink, root.accent) : "transparent"
              borderSpec: Border.controlSpec(hot ? "hover-cursor" : "normal",
                root.ink, root.accent)

              MouseArea {
                id: finishedMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.view = "finished"
              }

              Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(7)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: Model.GLYPH_CHECK
                  textFormat: Text.PlainText
                  color: finishedButton.hot ? root.accent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Finished"
                  textFormat: Text.PlainText
                  color: root.ink
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
              }

              Text {
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                text: root.finishedTotal === 1 ? "1 download" : root.finishedTotal + " downloads"
                textFormat: Text.PlainText
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }

          Column {
            width: parent.width
            visible: root.finishedView
            spacing: Style.space(10)

            JobList {
              width: parent.width
              jobs: root.doneList
              service: service
              now: service.now
              foreground: root.ink
              accent: root.accent
              fontFamily: root.fontFamily
              emptyText: "No finished downloads."
            }

            Text {
              width: parent.width
              text: "Click a finished download to play it in mpv. Esc or Enter goes back."
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
