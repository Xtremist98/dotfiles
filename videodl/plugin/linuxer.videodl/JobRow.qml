import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// One download: what it is, how far along it is, and the actions that make
// sense in its current state. It is the full width of the single-pane panel
// (440px), so long titles and specs elide rather than wrap.
Rectangle {
  id: root

  // The job record from the host, the polling service that can act on it, and
  // the tick source so elapsed/ETA keep moving between polls.
  property var job: null
  property var service: null
  property double now: Date.now()

  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property string fontFamily: ""

  readonly property color urgent: Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string status: job ? String(job.status) : ""
  readonly property bool active: Model.isActive(job)
  readonly property bool failed: status === "failed"
  readonly property string thumbPath: job && job.thumb ? String(job.thumb) : ""

  readonly property color statusColor: failed ? urgent
    : status === "cancelled" ? dim
    : active ? accent
    : foreground

  readonly property real padding: Style.space(8)
  readonly property real thumbWidth: Style.space(56)
  readonly property real thumbHeight: Style.space(34)

  width: parent ? parent.width : Style.space(260)
  // Text column carries the height; the action chips usually fit inside it.
  implicitHeight: content.implicitHeight + padding * 2

  radius: Style.cornerRadius
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, rowClick.containsMouse && openable ? 0.11 : 0.05)
  border.width: 1
  border.color: Qt.rgba(foreground.r, foreground.g, foreground.b,
    rowClick.containsMouse && openable ? 0.22 : 0.10)

  // Clicking a finished download plays it in mpv. Declared before the content
  // Row so the action chips stay on top and keep getting their own clicks.
  readonly property bool openable: status === "completed"

  MouseArea {
    id: rowClick
    anchors.fill: parent
    enabled: root.openable
    acceptedButtons: Qt.LeftButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.service) root.service.act("open", root.job.id)
  }

  Row {
    id: content
    x: root.padding
    y: root.padding
    width: root.width - root.padding * 2
    spacing: root.padding

    // --- thumbnail -------------------------------------------------------
    Rectangle {
      id: thumbBox
      width: root.thumbWidth
      height: root.thumbHeight
      radius: Math.min(Style.space(4), height / 2)
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
      clip: true

      SizedImage {
        id: thumbImage
        anchors.fill: parent
        url: root.thumbPath
        crop: true
        asynchronous: true
        visible: root.thumbPath !== "" && status === Image.Ready
      }

      Text {
        anchors.centerIn: parent
        visible: !thumbImage.visible
        text: root.failed ? Model.GLYPH_ALERT : Model.GLYPH_DOWNLOAD
        font.family: root.fontFamily
        font.pixelSize: Style.space(13)
        color: root.dim
      }
    }

    // --- text ------------------------------------------------------------
    Column {
      id: textBox
      // Whatever the thumbnail and the action chips leave behind.
      width: Math.max(Style.space(80),
        content.width - thumbBox.width - actionsBox.width - content.spacing * 2)
      spacing: Style.space(1)

      Text {
        width: parent.width
        text: Model.title(root.job)
        textFormat: Text.PlainText
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
        color: root.foreground
      }

      // Spec on the left, state on the right. The two are separate anchors
      // rather than two children of a Row: a Row sized both from the spec's
      // implicit width, so a long badge ("1080p · vp9 · mkv · thumb+tags")
      // pushed the state label into the middle of the line.
      Item {
        width: parent.width
        height: specText.implicitHeight

        Text {
          id: specText
          anchors.left: parent.left
          width: Math.max(0, parent.width - statusText.width - Style.space(8))
          text: Model.spec(root.job)
          textFormat: Text.PlainText
          elide: Text.ElideRight
          maximumLineCount: 1
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          color: root.dim
        }

        Text {
          id: statusText
          anchors.right: parent.right
          text: Model.statusLabel(root.job)
          textFormat: Text.PlainText
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.weight: root.active ? Font.DemiBold : Font.Normal
          color: root.statusColor
        }
      }

      ProgressLine {
        width: parent.width
        visible: root.active
        value: Model.percent(root.job)
        thickness: Style.space(3)
        fillColor: root.accent
      }

      Text {
        width: parent.width
        text: root.metaLine
        textFormat: Text.PlainText
        elide: Text.ElideRight
        maximumLineCount: root.failed ? 3 : 1
        wrapMode: root.failed ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        color: root.failed ? root.urgent : root.dim
      }
    }

    // --- actions ---------------------------------------------------------
    Column {
      id: actionsBox
      spacing: Style.space(2)

      PanelActionButton {
        visible: root.active
        size: Style.space(20)
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        iconText: Model.GLYPH_CLOSE
        tooltipText: "Cancel download"
        foreground: root.dim
        hoverColor: root.urgent
        bordered: true
        focusable: true
        onClicked: if (root.service) root.service.act("cancel", root.job.id)
      }

      PanelActionButton {
        visible: !root.active && (root.failed || root.status === "cancelled")
        size: Style.space(20)
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        iconText: Model.GLYPH_RETRY
        tooltipText: "Download again"
        foreground: root.dim
        hoverColor: root.accent
        bordered: true
        focusable: true
        onClicked: if (root.service) root.service.act("retry", root.job.id)
      }

      PanelActionButton {
        visible: root.status === "completed"
        size: Style.space(20)
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        iconText: Model.GLYPH_OPEN
        tooltipText: "Play in mpv"
        foreground: root.dim
        hoverColor: root.accent
        bordered: true
        focusable: true
        onClicked: if (root.service) root.service.act("open", root.job.id)
      }

      PanelActionButton {
        visible: root.status === "completed"
        size: Style.space(20)
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        iconText: Model.GLYPH_FOLDER
        tooltipText: "Show in folder"
        foreground: root.dim
        hoverColor: root.accent
        bordered: true
        focusable: true
        onClicked: if (root.service) root.service.act("reveal", root.job.id)
      }

      PanelActionButton {
        visible: !root.active
        size: Style.space(20)
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        iconText: Model.GLYPH_TRASH
        tooltipText: "Remove from the list"
        foreground: root.dim
        hoverColor: root.urgent
        bordered: true
        focusable: true
        onClicked: if (root.service) root.service.act("remove", root.job.id)
      }
    }
  }

  // One line that answers "how much, how fast, how long" for whatever state the
  // job is in. Reading service.now keeps it re-evaluating between polls.
  readonly property string metaLine: {
    var job = root.job
    if (!job) return ""
    var tick = root.service ? root.service.now : root.now
    var parts = []
    if (root.active) {
      var moved = Model.transferred(job)
      if (moved !== "") parts.push(moved)
      var rate = Model.speed(job.speed)
      if (rate !== "") parts.push(rate)
      var eta = Number(job.eta) || 0
      if (eta > 0) parts.push(Model.duration(eta) + " left")
      else {
        var running = Model.elapsed(job, tick)
        if (running !== "") parts.push(running + " elapsed")
      }
      if (parts.length === 0) parts.push(Model.statusLabel(job))
      return parts.join(" · ")
    }
    if (root.status === "completed") {
      var size = Model.bytes(job.size)
      if (size !== "" && size !== "0 B") parts.push(size)
      var at = Model.clock(job.finished)
      if (at !== "") parts.push(at)
      var took = Model.elapsed(job, tick)
      if (took !== "") parts.push("in " + took)
      return parts.join(" · ")
    }
    var problem = String(job.error || "").trim()
    if (problem !== "") return problem
    return Model.statusLabel(job)
  }
}
